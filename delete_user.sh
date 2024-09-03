#!/bin/bash
set -euo pipefail

COLOR_RED="\033[0;31m"
COLOR_GREEN="\033[0;32m"
COLOR_PLAIN="\033[0m"

function info {
  echo -e "${COLOR_GREEN}$@${COLOR_PLAIN}"
}

function error {
  echo -e "${COLOR_RED}$@${COLOR_PLAIN}" >&2
}

delete_user() {
  local username="$1"

  if id "${username}" >/dev/null 2>&1; then
    info "Deleting user '${username}'..."
    
    if userdel "${username}"; then
      info "User '${username}' deleted."
      return 0  # Success
    else
      error "Failed to delete user '${username}'."
      return 1  # Error during deletion
    fi
  else
    error "User '${username}' does not exist."
    return 2  # User does not exist
  fi
}

# Example usage: ./delete_user.sh username
if [ "$#" -ne 1 ]; then
    error "Usage: $0 <username>"
    exit 1  # Incorrect usage
fi

delete_user "$1"
exit_code=$?

# Exit the script with the exit code returned by the function
exit $exit_code
