name: Test Installers

on:
  push:
    branches:
      - main
  pull_request:
    branches:
      - main

jobs:
  test-windows:
    runs-on: windows-latest
    
    steps:
    - name: Checkout repository
      uses: actions/checkout@v2

    - name: List repository files
      run: dir

    - name: Install Chocolatey (if needed)
      run: |
        Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
        iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

    - name: Run Windows Installer Script
      run: powershell.exe -ExecutionPolicy Bypass -File .\install-Window.ps1
