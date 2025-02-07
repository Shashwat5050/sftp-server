# SFTP Server Documentation

This documentation outlines the setup and usage of an SFTP server designed to share a single directory among multiple SFTP users. The server is configured to use a common directory for all users, eliminating the need for separate home directories.

## Overview

This SFTP server is ideal for applications that require multiple users to access and manage a shared directory. Each user can be given unique credentials, and they all share access to the same directory structure, simplifying the management of shared resources.

### Features

- **Shared Directory**: All users share a common directory, which can be used for collaborative work.
- **Dynamic User Management**: Users can be added, deleted, or updated dynamically using provided scripts.
- **Password Encryption**: The server supports MD5-encrypted passwords, ensuring secure authentication.
- **Environment Variables**: Easily configure multiple users through environment variables.
- **Scriptable Management**: Scripts are provided for creating, deleting, updating users, and fetching user information, each returning proper exit codes for integration with automation tools like Nomad.

## Requirements

- **Docker** (for containerized deployment)
- **Bash** (for running management scripts)

## Environment Variables

To configure SFTP users, pass their details as environment variables when running the Docker container. Each user is defined by a set of three environment variables:

- `USER1`, `PASS1`, `UID1` for the first user.
- `USER2`, `PASS2`, `UID2` for the second user.
- `USER3`, `PASS3`, `UID3` for the third user, and so on.

## Scripts Available

Below scripts are available for external applications which can ssh into the container. This will help us to dynamically create users inside the container without restarting the sshd process.

1. create_user.sh username password uid
2. delete_user.sh username
3. update_user_password.sh username password
4. update_username.sh old_username new_username

# How to debug sftp server

1. Create Docker Image
- Run `docker build .` in project root directory.

2. Start Docker container using above created image
- Run `docker run -p 22:22 -v /userconf:/userconf -v <folder path which needs to be mounted>:/data/incoming  <docker image id>` to start sftp server on port 22 which will allow all the users to connect to the sftp server. It will host the folder-path provided.
- This will by default create one user with username `test` and password `123`.

3. Pass users in env of the docker container
- If you want to create users when the container is just started, you can pass env to create users. Below is an updated command for the same.
- `docker run -p 22:22 -v /userconf:/userconf -v <folder path which needs to be mounted>:/data/incoming -e USER1=test1 PASS1=<encrypted password using crypt md5 algorithm> UID1=<random uid of the user>  <docker image id>`
