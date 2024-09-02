#!/bin/bash
set -euo pipefail

COLOR_GREEN="\033[0;32m"
COLOR_RED="\033[0;31m"
COLOR_PLAIN="\033[0m"

function info {
  echo -e "${COLOR_GREEN}$@${COLOR_PLAIN}"
}

function error {
  echo -e "${COLOR_RED}$@${COLOR_PLAIN}" >&2
}

update_username() {
  local old_username="$1"
  local new_username="$2"

  if id "${old_username}" >/dev/null 2>&1; then
    if ! id "${new_username}" >/dev/null 2>&1; then
      info "Updating username from '${old_username}' to '${new_username}'..."
      usermod -l "${new_username}" "${old_username}"
      info "Username updated successfully."
    else
      error "The username '${new_username}' already exists."
      exit 1
    fi
  else
    error "The user '${old_username}' does not exist."
    exit 1
  fi
}

# Example usage: ./update_username.sh old_username new_username
if [ "$#" -ne 2 ]; then
    error "Usage: $0 <old_username> <new_username>"
    exit 1
fi

update_username "$1" "$2"
