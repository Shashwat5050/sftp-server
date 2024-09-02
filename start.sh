#!/usr/local/bin/dumb-init /bin/bash
set -euo pipefail

COLOR_CYAN="\033[0;36m"
COLOR_PLAIN="\033[0m"

function info {
  echo -e "${COLOR_CYAN}$@${COLOR_PLAIN}"
}

function step {
    info "[$(date +%H:%M:%S)] $@"
}

step "Checking SSH host keys..."
for type in rsa dsa ecdsa ed25519; do
  if ! [ -e "/ssh/ssh_host_${type}_key" ]; then
    info "Generating /ssh/ssh_host_${type}_key..."
    ssh-keygen -f "/ssh/ssh_host_${type}_key" -N '' -t ${type} 2>&1 >/dev/null
  fi

  ln -sf "/ssh/ssh_host_${type}_key" "/etc/ssh/ssh_host_${type}_key"
done

groupadd -f sftpusers  
chown root:sftpusers /data/incoming
chmod 770 /data/incoming

# Function to create a user
create_user() {
  local username="$1"
  local password="$2"
  local uid="${3:-1000}"  # Use default UID if not provided

  if id "${username}" >/dev/null 2>&1; then
    echo "User '${username}' already exists."
  else
    echo "Creating user '${username}'."
    useradd -d /data -m -p "${password}" -u "${uid}" -s /bin/sh "${username}"
    usermod -aG sftpusers ${username}
    echo "User '${username}' created with password '${password}'."
  fi
}

# Find the highest index of users
max_index=-1
for var in $(env | grep -E '^USER[0-9]+=' | cut -d'=' -f1); do
  index=$(echo "$var" | sed 's/USER//')
  if (( index > max_index )); then
    max_index=$index
  fi
done

# If no users were found, skip the user creation loop
if (( max_index >= 0 )); then
  # Iterate through environment variables and create users
  for i in $(seq 0 "$max_index"); do
    user_var="USER${i}"
    pass_var="PASS${i}"
    uid_var="UID${i}"
    
    username=${!user_var:-}
    password=${!pass_var:-}
    uid=${!uid_var:-}
    
    if [ -n "${username}" ] && [ -n "${password}" ]; then
      create_user "${username}" "${password}" "${uid}"
    else
      echo "Environment variables for ${user_var}, ${pass_var}, or ${uid_var} are not fully set."
    fi
  done
else
  echo "No users to create."
fi

step "Running SSHd..."
exec /usr/sbin/sshd -D
