#!/usr/local/bin/dumb-init /bin/bash
set -euo pipefail

COLOR_CYAN="\033[0;36m"
COLOR_PLAIN="\033[0m"

function info {
  echo -e "${COLOR_CYAN}$@${COLOR_PLAIN}"
}

function step {
  info "[$(date +%H:%M:%S)] $@"
}

# file location where i am storing the users data
#  it will be mounted on the host file system to ensure data backup for next docker run state
USERS_FILE=/userconf/users.conf

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
    # update the existing user's password
    # Escape special characters in username and password for sed
    safe_username=$(printf '%s' "$username" | sed 's/[&/\]/\\&/g')
    safe_password=$(printf '%s' "$password" | sed 's/[&/\]/\\&/g')
    echo "user configuration : update password"
    # sed -i "s/^$username:[^:]*:/$username:$password:/" "$USERS_FILE"
    if ! sed -i "s|^$safe_username:[^:]*:|$safe_username:$safe_password:|" "$USERS_FILE"; then
      echo "Error: Failed to update password for user '$safe_username'."
      return 1
    fi
    echo "user configuration : Password for user '$username' updated successfully."
  # elif grep -q ":$uid$" "$USERS_FILE"; then
  #   # update the existing user's password
  #   echo "user configuration : create new user with new uid"
  #   echo "$username:$password:$uid" >> "$USERS_FILE"
  #   echo "user configuration : User '$username' added successfully with new UID '$uid'."
  else
    # add the new user
    echo "user configuration : create new user"
    echo "$username:$password:$uid" >>"$USERS_FILE"
    echo "user configuration : User '$username' added successfully."
  fi
}

# Function to create a user in the container
create_user() {
  local username="$1"
  local password="$2"
  local uid="$3"

  if id "${username}" >/dev/null 2>&1; then
    echo "user creation : user '${username}' already exists."
  else
    useradd -d /data -m -p "${password}" -u "${uid}" -s /bin/sh "${username}"
    usermod -aG root ${username}
    usermod -g root ${username}
    echo "user creation : user '${username}' created with password '${password}'."
  fi
}

# Assuming that the users.conf file contains the original and updated data
# Function to iterate over all users and print their details
create_users() {
  echo "Iterating all the users present in the ${USERS_FILE} file and adding them to the container..."
  while IFS=":" read -r username password uid; do
    create_user "${username}" "${password}" "${uid}"
  done <"$USERS_FILE"
}

# check if the users.conf file exists
if [ ! -f "$USERS_FILE" ]; then
  echo "Error: $USERS_FILE does not exist."
  exit 1
fi

step "checking SSH host keys..."
for type in rsa ecdsa ed25519; do
  if ! [ -e "/ssh/ssh_host_${type}_key" ]; then
    info "Generating /ssh/ssh_host_${type}_key..."
    ssh-keygen -f "/ssh/ssh_host_${type}_key" -N '' -t ${type} 2>&1 >/dev/null
  fi

  ln -sf "/ssh/ssh_host_${type}_key" "/etc/ssh/ssh_host_${type}_key"
done

# Add sftp users group with access granting on /data/incoming folder
# groupadd -f sftpusers
chown -R nobody:nobody /data/incoming
chmod 770 /data/incoming

# Find the highest index of users
max_index=-1
for var in $(env | grep -E '^USER[0-9]+=' | cut -d'=' -f1); do
  index=$(echo "$var" | sed 's/USER//')
  if ((index > max_index)); then
    max_index=$index
  fi
done

# If users are there, then iterate over them and update the users.conf actual data file
step "user configuration : update users.conf file based on the environment variables"
if ((max_index >= 0)); then
  # Iterate through environment variables and create users
  for i in $(seq 0 "$max_index"); do
    user_var="USER${i}"
    pass_var="PASS${i}"
    uid_var="UID${i}"

    username=${!user_var:-}
    password=${!pass_var:-}
    uid=${!uid_var:-}

    echo "adding user: ${username} and password: ${password}"

    if [ -n "${username}" ] && [ -n "${password}" ]; then
      add_user "${username}" "${password}"
    else
      echo "Environment variables for ${user_var}, ${pass_var}, or ${uid_var} are not fully set."
    fi
  done
else
  echo "No users to create."
fi

# Now iterate over all the users present inside the uesrs.conf and update the container with the latest data

step "create users based on the users.conf file data"
create_users

# ls -al /var
chown root:root /var/empty
chmod 755 /var/empty

step "Running SSHd..."
exec /usr/sbin/sshd -D

if [ $? -ne 0 ]; then
  echo "Error: Failed to start SSH daemon."
  exit 2
fi
