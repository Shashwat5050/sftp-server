#!/usr/local/bin/dumb-init /bin/bash
set -euo pipefail

COLOR_PLAIN="\033[0m"
COLOR_RED="\033[0;31m"

# Function to log info messages
function info {
  echo -e "[INFO] [$(date '+%Y-%m-%d %H:%M:%S')]: $@"
}

# Function to log error messages
function error {
  echo -e "${COLOR_RED}[ERROR] [$(date '+%Y-%m-%d %H:%M:%S')]: $@${COLOR_PLAIN}"
}

# File location where users data will be stored for persistent storage.
# It will be mounted on the host file system to ensure data backup for next docker run state.
# Data should be persitent across multiple docker start stop operations.
USERS_DATA_FOLDER=/userconf # Mounted on the host file system for data persistence.
USERS_FILE=$USERS_DATA_FOLDER/users.conf

# Check if the users.conf file exists
if [ ! -f "$USERS_FILE" ]; then
  # If the file does not exist, create it.
  touch "$USERS_FILE"
  error "users.conf file does not exist, Created users.conf file at $USERS_FILE"
else
  info "users.conf file already exists."
fi

# Function to generate a random UID that does not already exist in the users.conf file
generate_uid() {
  while true; do
    uid=$(shuf -i 1000-9999 -n 1) # Generate a random UID between 1000 and 9999
    if ! grep -q ":$uid$" "$USERS_FILE"; then
      echo "$uid"
      return 0
    fi
  done
}

# Function to add a user or update the password if the user already exists in users.conf file
add_user() {
  username="$1"
  password="$2"
  uid=$(generate_uid)

  # Check if the username exists
  if grep -q "^$username:" "$USERS_FILE"; then
    # Update the existing user's password
    # Escape special characters in username and password for sed
    safe_username=$(printf '%s' "$username" | sed 's/[&/\]/\\&/g')
    safe_password=$(printf '%s' "$password" | sed 's/[&/\]/\\&/g')

    info "Update password for user ${username}"
    if ! sed -i "s|^$safe_username:[^:]*:|$safe_username:$safe_password:|" "$USERS_FILE"; then
      error "Failed to update password for user '$safe_username'."
      return 1
    fi
    info "Password of user '$username' updated successfully."
  else
    echo "$username:$password:$uid" >>"$USERS_FILE"
    info "User '$username' added successfully."
  fi
}

# Function to create a user in the container
create_user() {
  local username="$1"
  local password="$2"
  local uid="$3"

  if id "${username}" >/dev/null 2>&1; then
    info "User '${username}' already exists."
  else
    # Create user with given uid, username, and password
    info "Creating user '${username}' with uid '${uid}'."
    useradd -d /data -m -p "${password}" -u "${uid}" -s /bin/sh "${username}"

    # Add to nogroup group as secondary group
    usermod -a -G nogroup ${username}
    info "User '${username}' created."
  fi
}

# Assuming that the users.conf file contains the original and updated data
# Function to iterate over all users and print their details
create_users() {
  info "Iterating all the users present in the ${USERS_FILE} file and adding them to the container..."
  while IFS=":" read -r username password uid; do
    create_user "${username}" "${password}" "${uid}"
  done <"$USERS_FILE"
}

# Set key directory
KEY_DIR="/etc/ssh"
mkdir -p "$KEY_DIR"

# Define key types to generate
# NOTE: for simplicity we will be using one key type only. Add HostKey in the sshd_config if updating key types.
KEY_TYPES=("rsa")

# Function to generate a host key if it does not exist
generate_host_key() {
  local key_type=$1
  local key_path="$KEY_DIR/ssh_host_${key_type}_key"

  if [[ ! -f "$key_path" ]]; then
    info "Generating SSH $key_type host key..."
    ssh-keygen -t "$key_type" -f "$key_path" -N "" -q
    chmod 600 "$key_path"
    info 644 "$key_path.pub"
    info "Host key generated: $key_path"
  else
    info "Host key already exists: $key_path"
  fi
}

# Generate keys for each type
for key in "${KEY_TYPES[@]}"; do
  generate_host_key "$key"
done

# Add nobody group with access granting on /data/incoming folder
# Allow everyone to access /data/incoming folder
chown -R nobody:nogroup /data/incoming
chmod -R 777 /data/incoming
info "Permissions granted on /data/incoming folder."

# Find the highest index of users
max_index=-1
for var in $(env | grep -E '^USER[0-9]+=' | cut -d'=' -f1); do
  index=$(echo "$var" | sed 's/USER//')
  if ((index > max_index)); then
    max_index=$index
  fi
done

# If users are there, then iterate over them and update the users.conf actual data file
info "user configuration : update users.conf file based on the environment variables"
if ((max_index >= 0)); then
  # Iterate through environment variables and create users
  for i in $(seq 0 "$max_index"); do
    user_var="USER${i}"
    pass_var="PASS${i}"
    uid_var="UID${i}"

    username=${!user_var:-}
    password=${!pass_var:-}
    uid=${!uid_var:-}

    info "Adding user '${username}' to configuration file."

    if [ -n "${username}" ] && [ -n "${password}" ]; then
      add_user "${username}" "${password}"
    else
      echo "Environment variables for ${user_var}, ${pass_var}, or ${uid_var} are not fully set."
    fi
  done
else
  info "No new users to create."
fi

# Now iterate over all the users present inside the uesrs.conf and update the container with the latest data
info "Create users based on the users.conf file data"
create_users

chown root:root /var/empty
chmod 755 /var/empty

info "Running SSHd..."
exec /usr/sbin/sshd -D -e -f /etc/ssh/sshd_config

# NOTE
# -D : sshd will not detach and does not become a daemon. This allows easy monitoring of sshd.
# -f : Specifies the path to the sshd configuration file.
# -e : When this option is specified, sshd will send the output to the standard error instead of the system log.
