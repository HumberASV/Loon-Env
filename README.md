# Loon-Env

Loon-Env is the full package for setting up Loon-E's development environment.

> ![Important](https://img.shields.io/badge/Important-Read%20Before%20Editing-orange) ![License](https://img.shields.io/badge/License-MIT-green) ![Last%20Updated](https://img.shields.io/badge/Last%20Updated-2026--05--25-blue)

> [!IMPORTANT]
> ANY changes you make to the local ./Loon-Env directory will be reflected upon running the LoonEnv script, which will copy necessary files to the installation directory and set up the ROS 2 workspace.

Read this README before making any changes to the Loon-Env repository. It contains important information about how the environment is set up and how to use the LoonEnv script.

## Description

This repository contains `LoonEnv`, a setup script that checks for required dependencies and can install them automatically. It adds environment variables to the user's bashrc, installs Docker and the correct ZED SDK, installs the LoonE script into the system bin directory and its assets to /opt/, configures the MTU for the ZEDX wrapper, downloads LoonE and ZEDX packages and their dependencies, and creates a ROS 2 workspace. `LoonEnv` also provides verbose and dry-run modes for debugging.

It also includes the `LoonE` script, a convenient wrapper for managing the Docker environment for the Loon-E project. It can build the Docker image, start the container, and enter it with a single command. :)

## Getting Started

To get started with Loon-Env, check you have the dependencies listed below, then run the `LoonEnv` script. This will set up the environment and install necessary dependencies for the Loon-E project.

### Dependencies

- Ubuntu 22.04 or later
- Jetson Orin Nano
- Jetpack 5.0 or later

Follow instruction from [NVIDIA's official documentation](https://www.jetson-ai-lab.com/tutorials/initial-setup-jetson-orin-nano/) to set up your Jetson Orin Nano with the appropriate Jetpack version.

### Installation

Clone the Loon-Env repository to your local machine:

```bash
     git clone --recurse-submodules https://github.com/HumberASV/Loon-Env.git
```

### Execution

Enter the repository directory, give the `LoonEnv` script execute permissions, and run it:

```bash
     cd Loon-Env
     sudo chmod +x LoonEnv
     ./LoonEnv
```

> [!IMPORTANT]
> The LoonEnv script will perform several operations that may require sudo privileges, such as installing dependencies, permissions, and modifying system files. Make sure to review the script and understand the changes it will make to your system before running it. Dry-run mode can be used to see the commands that will be executed without making any changes.
> ```bash
>     ./LoonEnv --dry-run
> ```


## Help

Inside this repo is a `wiki/` directory containing documentation for the Loon-Env repository. 
