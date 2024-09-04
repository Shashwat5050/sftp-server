#!/bin/bash
set -euo pipefail

COLOR_CYAN="\033[0;36m"
COLOR_PLAIN="\033[0m"

function info {
  echo -e "${COLOR_CYAN}$@${COLOR_PLAIN}"
}

# file location where i am storing the users data
#  it will be mounted on the host file system to ensure data backup for next docker run state
USERS_FILE=/userconf/users.conf

# Function to add a user or update the password if the user already exists in users.conf file
add_user() {
  username="$1"
  password="$2"
  uid="$3"

  # Check if the username exists
  if grep -q "^$username:" "$USERS_FILE"; then
    # update the existing user's password
    sed -i "s/^$username:[^:]*:/$username:$password:/" "$USERS_FILE"
    create_user "$username" "$password" "$uid"
    echo "user configuration : password for user '$username' updated successfully."
    return 0
  elif grep -q ":$uid$" "$USERS_FILE"; then
    # update the existing user's password
    uid=$(generate_uid)
    echo "$username:$password:$uid" >> "$USERS_FILE"
    create_user "$username" "$password" "$uid"
    echo "user configuration : user '$username' added successfully with new UID '$uid'."
    return 0
  else
    # add the new user
    echo "$username:$password:$uid" >> "$USERS_FILE"
    create_user "$username" "$password" "$uid"
    echo "user configuration : user '$username' added successfully."
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
    if usermod -p "${password}" "${username}"; then
      info "user creation: password for user '${username}' has been updated."
      return 0
    else
      error "user creation: failed to update password for user '${username}'."
      return 1
    fi

    return 0
  else
    if useradd -d /data -m -p "${password}" -u "${uid}" -s /bin/sh "${username}"; then
      usermod -aG sftpusers "${username}"
      info "user creation: user '${username}' created with password '${password}'."
      return 0
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

add_user "$username" "$password" "$uid"
exit $?