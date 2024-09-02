#!/bin/bash
set -euo pipefail

COLOR_GREEN="\033[0;32m"
COLOR_CYAN="\033[0;36m"
COLOR_RED="\033[0;31m"
COLOR_PLAIN="\033[0m"

function info {
  echo -e "${COLOR_CYAN}$@${COLOR_PLAIN}"
}

function success {
  echo -e "${COLOR_GREEN}$@${COLOR_PLAIN}"
}

function error {
  echo -e "${COLOR_RED}$@${COLOR_PLAIN}"
}

update_password() {
  local username="$1"
  local new_password="$2"

  if id "${username}" >/dev/null 2>&1; then
    info "Updating password for user '${username}'."
    echo "${username}:${new_password}" | chpasswd
    success "Password for user '${username}' has been updated."
  else
    error "User '${username}' does not exist."
  fi
}

# Example usage: ./update_password.sh username new_password
update_password "$1" "$2"
