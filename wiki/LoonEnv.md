# Loon-Env

A script that sets up a environment for the Loon-E project.

The LoonEnv script will perform the following tasks:

1. Create a group for Loon-Env users and add the current user to it
2. Check for and optionally install necessary dependencies
3. Set up environment variables for the workspace and docker images
4. Install LoonE scripts and assets to the installation directory
5. Create a ROS 2 workspace with necessary subdirectories for LoonE and ZEDX packages

Loon-Env will set up the following directory structure for the ROS 2 workspace:

```
${LOONE_WORKSPACE_DIR}
|-- zedx_ws/
     |-- src
|-- loone_ws/
     |-- src
|-- docker/
     |-- Zedx/
     |-- Loone/
```

## Description

### Environment Variables
| Name | Purpose |
|---|---|
LOONE_FILES_DIR | Directory where Loon-Env files are located (default: /opt/loon_env)
LOONE_WORKSPACE_DIR | Directory for the ROS 2 workspaces (default: $HOME/LoonE_ws)
LOONE_SETUP_SCRIPT | Path to the setup script for sourcing the workspace (default: $HOME/.loon_env_setup.bash)


# Loon-Env v5

Loon-Env v5 is the latest version of the Loon-Env script, which includes several improvements and new features compared to previous versions. Some of the key changes in v5 include:

* set up new loon_hub script which contains universal functions for managing LoonE and ZEDX environments
* set up Isaac Sim environment variables
* set up IsaacBridge script and assets
* set up BaseStation script and assets
* Improved LoonTools for base station and sim bridge management


## Setting Up Isaac Sim

## Setting UP Isaac Bridge script

## Setting Up Base Station script
