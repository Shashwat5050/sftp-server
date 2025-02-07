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

# File location where users data will be stored for persistent storage.
# It will be mounted on the host file system to ensure data backup for next docker run state.
# Data should be persitent across multiple docker start stop operations.
USERS_DATA_FOLDER=/userconf # Mounted on the host file system for data persistence.
USERS_FILE=$USERS_DATA_FOLDER/users.conf

delete_user() {
  local username="$1"

  if id "${username}" >/dev/null 2>&1; then
    info "Deleting user '${username}'..."
    if userdel "${username}"; then
      info "User '${username}' deleted."
      sed -i "/^${username}:/d" /data/users.conf
      return 0
    else
      error "Failed to delete user '${username}'."
      return 1
    fi
  else
    error "User '${username}' does not exist."
    return 2
  fi
}

delete_user "$1"
exit $?
