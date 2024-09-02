#!/bin/bash
set -euo pipefail

COLOR_CYAN="\033[0;36m"
COLOR_PLAIN="\033[0m"

function info {
  echo -e "${COLOR_CYAN}$@${COLOR_PLAIN}"
}

create_user() {
  local username="$1"
  local password="$2"
  local uid="${3:-1000}"  # Use default UID if not provided

  if id "${username}" >/dev/null 2>&1; then
    info "User '${username}' already exists."
    return 1  # Exit with code 1 if user already exists
  else
    info "Creating user '${username}'."
    # local enc_pass=$(echo "${password}" | openssl passwd -1 -stdin)
    if useradd -d /data -m -p "${password}" -u "${uid}" -s /bin/sh "${username}"; then
      # add user to sftp_users group
      usermod -aG sftpusers ${username}
      info "User '${username}' added to the sftp_users group."
      info "User '${username}' created with password '${password}'."
      return 0  # Exit with code 0 on successful creation
    else
      info "Failed to create user '${username}'."
      return 2  # Exit with code 2 if user creation fails
    fi
  fi
}

# Example usage: ./create_user.sh username password [uid]
create_user "$1" "$2" "${3:-1000}"
exit_code=$?

# Exit the script with the exit code returned by the function
exit $exit_code
