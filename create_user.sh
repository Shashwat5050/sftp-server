#!/bin/bash
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

# File location where users data will be stored for persistent storage.
# It will be mounted on the host file system to ensure data backup for next docker run state.
# Data should be persitent across multiple docker start stop operations.
USERS_DATA_FOLDER=/userconf # Mounted on the host file system for data persistence.
USERS_FILE=$USERS_DATA_FOLDER/users.conf

# Function to add a user or update the password if the user already exists in users.conf file
add_user() {
  username="$1"
  password="$2"
  uid=$(generate_uid)

  # Check if the username exists
  if grep -q "^$username:" "$USERS_FILE"; then
    # update the existing user's password
    sed -i "s/^$username:[^:]*:/$username:$password:/" "$USERS_FILE"
    create_user "$username" "$password" "$uid"
    info "Password of user '$username' updated successfully."
    return 0
  elif grep -q ":$uid$" "$USERS_FILE"; then
    # update the existing user's password
    uid=$(generate_uid)
    echo "$username:$password:$uid" >>"$USERS_FILE"
    create_user "$username" "$password" "$uid"
    info "User '$username' added successfully with new UID '$uid'."
    return 0
  else
    # add the new user
    echo "$username:$password:$uid" >>"$USERS_FILE"
    create_user "$username" "$password" "$uid"
    info "User '$username' added successfully."
    return 0
  fi
}

# Function to create a user or update the password if the user already exists
create_user() {
  local username="$1"
  local password="$2"
  local uid="${3:-1000}"

  if id "${username}" >/dev/null 2>&1; then
    # Update the user's password if the user already exists
    info "User '$username' already exists. Trying to update the password of the user."
    if usermod -p "${password}" "${username}"; then
      info "Password for user '${username}' has been updated."
      return 0
    else
      error "Failed to update password for user '${username}'."
      return 1
    fi

    return 0
  else
    if useradd -d /data -m -p "${password}" -u "${uid}" -s /bin/sh "${username}"; then
      usermod -a -G nobody "${username}"
      # info "User '${username}' created with password '${password}'." # Uncomment this line to debug the password creation process.
      info "User '${username}' created."
      return 0
    else
      info "Failed to create user '${username}'."
      return 1
    fi
  fi
}

# call to update_user_password function
username="$1"
password="$2"

add_user "$username" "$password"
exit $?
