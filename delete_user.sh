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
