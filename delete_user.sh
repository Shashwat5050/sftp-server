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
    userdel "${username}"
    info "User '${username}' deleted."
  else
    error "User '${username}' does not exist."
  fi
}

# Example usage: ./delete_user.sh username
if [ "$#" -ne 1 ]; then
    error "Usage: $0 <username>"
    exit 1
fi

delete_user "$1"
