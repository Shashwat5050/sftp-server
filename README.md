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
