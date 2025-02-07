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

update_username() {
  local old_username="$1"
  local new_username="$2"

  if id "${old_username}" >/dev/null 2>&1; then
    if ! id "${new_username}" >/dev/null 2>&1; then
      info "Updating username from '${old_username}' to '${new_username}'..."
      if usermod -l "${new_username}" "${old_username}"; then
        info "Username updated successfully."
        return 0 # Success
      else
        error "Failed to update username from '${old_username}' to '${new_username}'."
        return 2 # Error during username update
      fi
    else
      error "The username '${new_username}' already exists."
      return 1 # New username already exists
    fi
  else
    error "The user '${old_username}' does not exist."
    return 3 # Old username does not exist
  fi
}

# Example usage: ./update_username.sh old_username new_username
if [ "$#" -ne 2 ]; then
  error "Usage: $0 <old_username> <new_username>"
  exit 1 # Incorrect number of arguments
fi

update_username "$1" "$2"
exit_code=$?

# Exit the script with the exit code returned by the function
exit $exit_code
