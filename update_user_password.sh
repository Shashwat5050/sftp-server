#!/bin/bash
set -euo pipefail

COLOR_RED="\033[0;31m"
COLOR_PLAIN="\033[0m"

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

# Function to update the user's password in the users.conf file
update_user_password() {
  username="$1"
  password="$2"
  uid="$3"

  # Check if the username exists
  if grep -q "^$username:" "$USERS_FILE"; then
    # Update the existing user's password
    sed -i "s/^$username:[^:]*:/$username:$password:/" "$USERS_FILE"
    create_user "$username" "$password" "$uid"
    echo "user configuration: password for user '$username' updated successfully."
  elif grep -q ":$uid$" "$USERS_FILE"; then
    # Update the existing user's password
    uid=$(generate_uid)
    echo "$username:$password:$uid" >>"$USERS_FILE"
    create_user "$username" "$password" "$uid"
    echo "user configuration: user '$username' added successfully with new UID '$uid'."
  else
    # Add the new user
    echo "$username:$password:$uid" >>"$USERS_FILE"
    create_user "$username" "$password" "$uid"
    echo "user configuration: user '$username' added successfully."
  fi
}

# Function to create or update the user's password in the container
create_user() {
  local username="$1"
  local password="$2"
  local uid="${3:-1000}"

  if id "${username}" >/dev/null 2>&1; then
    # Update the user's password if the user already exists
    if usermod -p "${password}" "${username}"; then
      info "user creation: password for user '${username}' has been updated."
    else
      info "user creation: failed to update password for user '${username}'."
      return 1
    fi
  else
    if useradd -d /data -m -p "${password}" -u "${uid}" -s /bin/sh "${username}"; then
      usermod -aG sftpusers "${username}"
      info "user creation: user '${username}' created with password '${password}'."
    else
      info "user creation: failed to create user '${username}'."
      return 1
    fi
  fi
}

# Example call to update_user_password function
username="$1"
password="$2"
uid="${3:-$(generate_uid)}"

update_user_password "$username" "$password" "$uid"
exit $?
