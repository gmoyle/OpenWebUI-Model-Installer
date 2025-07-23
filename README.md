# OpenWebUI + Ollama Installation and Uninstallation Scripts

This repository provides **installation** and **uninstallation scripts** for setting up and removing the **OpenWebUI** and **Ollama** containers on both **Windows** and **Mac** operating systems. The scripts automate the process of setting up the Docker environment, installing necessary dependencies, and ensuring everything is ready for use.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Installation](#installation)
  - [Windows](#windows)
  - [Mac](#mac)
- [Uninstallation](#uninstallation)
  - [Windows](#windows-1)
  - [Mac](#mac-1)
- [Troubleshooting](#troubleshooting)
- [FAQ](#faq)

---

## Prerequisites

Before running the installation scripts, make sure the following are installed:

- **Docker**: You must have **Docker Desktop** installed and running on your machine. 
  - [Download Docker Desktop](https://www.docker.com/products/docker-desktop)
- **WSL2 (Windows only)**: For Windows, WSL2 (Windows Subsystem for Linux) is required.
  - [Install WSL2](https://docs.microsoft.com/en-us/windows/wsl/install)

### Dependencies for Windows:

- **Chocolatey** (for Windows package management):
  - [Install Chocolatey](https://chocolatey.org/install)

### Dependencies for Mac:

- **Homebrew** (for package management on macOS):
  - [Install Homebrew](https://brew.sh/)

---

## Installation

### Windows

1. **Ensure Docker is installed**: The script will check if Docker is installed. If it's not, it will automatically install Docker Desktop via **Chocolatey**.
2. **Check for WSL2**: The script will check if WSL2 is installed. If not, it will prompt you to install it.
3. **Install necessary components**: The script will install and configure all dependencies automatically, including Docker, WSL2, and any necessary packages.
4. **Run the installation script**:
    - Download the Windows installation script (`install-windows.ps1`).
    - Open **PowerShell** as **Administrator**.
    - Run the script:
      ```powershell
      Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
      ./install-windows.ps1
      ```

The script will automatically handle Docker container setup, directory creation, and model selection based on your available memory.

### Mac

1. **Ensure Docker is installed**: The script will check if Docker is installed. If it's not, it will prompt you to install Docker.
2. **Install necessary components**: The script will automatically install dependencies using **Homebrew**.
3. **Run the installation script**:
    - Download the Mac installation script (`install-mac.sh`).
    - Open **Terminal** and navigate to the directory where you saved the script.
    - Run the script:
      ```bash
      bash install-mac.sh
      ```

The script will automatically set up Docker, configure containers, and start the services for **OpenWebUI** and **Ollama**.

---

## Uninstallation

### Windows

1. **Run the uninstallation script**:
    - Download the Windows uninstallation script (`uninstall-windows.ps1`).
    - Open **PowerShell** as **Administrator**.
    - Run the script:
      ```powershell
      Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
      ./uninstall-windows.ps1
      ```

The uninstaller will:
- Stop and remove Docker containers for **OpenWebUI** and **Ollama**.
- Remove Docker volumes and the data directory.
- Optionally, it will remove Docker Desktop if no other containers are running.

### Mac

1. **Run the uninstallation script**:
    - Download the Mac uninstallation script (`uninstall-mac.sh`).
    - Open **Terminal** and navigate to the directory where you saved the script.
    - Run the script:
      ```bash
      bash uninstall-mac.sh
      ```

The uninstaller will:
- Stop and remove Docker containers for **OpenWebUI** and **Ollama**.
- Remove Docker volumes and data directories.
- Optionally, it will remove Docker if no other containers are using it.

---

## Troubleshooting

If you run into any issues during installation or uninstallation, the following steps may help:

1. **Docker Not Running**:
   - Ensure **Docker Desktop** is running. If it’s not, start Docker and try again.
   
2. **WSL2 Configuration (Windows Only)**:
   - Ensure that **WSL2** is correctly installed. The script will prompt you if WSL2 is missing.
   
3. **Disk Space**:
   - Ensure you have enough disk space (at least 30GB free) for Docker containers to function smoothly.

4. **Permissions**:
   - Ensure the script is run with **Administrator** privileges on Windows, or with **sudo** on macOS if needed.

---

## FAQ

### **Q: Do I need to manually install Docker?**
- **A**: No, the script will automatically install Docker if it's not already installed. For Windows, it uses **Chocolatey** to install Docker Desktop, and for macOS, it uses **Homebrew**.

### **Q: What if I don’t have **WSL2** (Windows Only)?**
- **A**: If WSL2 is not installed, the script will prompt you to install it automatically using the `wsl --install` command.

### **Q: What happens if I run the script without administrator rights?**
- **A**: If you don't run the script as **Administrator** on Windows, it will prompt you to do so. On macOS, you’ll be asked to use `sudo` if necessary.

### **Q: Can I change the default model used by **Ollama**?**
- **A**: Yes, the installation script detects your available memory and will prompt you to select the best model for your system. You can also modify the `docker-compose.yml` file manually for custom configurations.

---

### Contribution

Feel free to fork the repository and create pull requests to improve these scripts. If you encounter any issues, open an issue in the **Issues** section of this repository.

---

### License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---
