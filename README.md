# Microsoft Endpoint Configuration Manager (MEMCM) Setup Scripts

This repository contains a set of PowerShell scripts for automating the setup and configuration of Microsoft Endpoint Configuration Manager (MEMCM) in a Windows Server environment.

## Overview

There are several scripts in this repository:

1. **memcm-ports.ps1** - This script checks the availability of required ports between the MEMCM servers and other servers in the environment.

2. **memcm-unattend-generator.ps1** - This script automates the installation and configuration of MEMCM, including the setup of a primary site and several secondary sites.

3. **memcm-prepare.ps1** - This script checks and installs the necessary prerequisites for MEMCM setup on Windows Server, including Windows features and .NET Framework 3.5.

All scripts are designed to work with a JSON configuration file that defines necessary parameters like server names and file URLs.

## Requirements

- PowerShell 5.1 or higher
- Administrative access to the servers
- Access to the internet or local network resources to download necessary files

## Usage

1. Clone this repository to your local system:

```
git clone https://github.com/WinSCaP/githubMEMCM.git
```

2. Edit the `config.json` file with your specific parameters.

3. Run the scripts in an administrative PowerShell session. For example:

```powershell
.\memcm-unattend-generator.ps1
```

## Note

These scripts are provided as-is and should be used as a starting point for your configuration. They may require modifications to suit your specific environment and requirements.
