# Loon-Env

A script that sets up a environment for the Loon-E project.

The LoonEnv script will perform the following tasks:

1. create a group for Loon-Env users and add the current user to it
1. check for and optionally install necessary dependencies
2. set up environment variables for the workspace and docker images
3. install LoonE scripts and assets to the installation directory
4. create a ROS 2 workspace with necessary subdirectories for LoonE and ZEDX packages

## Description

### Environment Variables
| Name | Purpose |
|---|---|
LOONE_FILES_DIR | Directory where Loon-Env files are located (default: /opt/loon_env)
LOONE_WORKSPACE_DIR | Directory for the ROS 2 workspaces (default: $HOME/LoonE_ws)
LOONE_SETUP_SCRIPT | Path to the setup script for sourcing the workspace (default: $HOME/.loon_env_setup.bash)

