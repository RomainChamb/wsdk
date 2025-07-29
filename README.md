<p align="center">
  <img src="assets/wsdk_logo.png" alt="wsdk logo" width="300"/>
</p>


# WSDK - Windows SDK Manager

![Version](https://img.shields.io/github/v/release/RomainChamb/wsdk)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![PowerShell](https://img.shields.io/badge/PowerShell-5.1+-blue.svg)](https://github.com/PowerShell/PowerShell)


WSDK is a lightweight, PowerShell-based SDK manager for Windows that helps developers manage multiple versions of development tools. It allows you to easily switch between different versions of tools without conflicts. No administrative privileges are required for installation or usage.

## Features

- **Version Management**: Install and switch between different versions of development tools
- **Simple CLI**: Easy-to-use command-line interface
- **Environment Setup**: Automatically configures environment variables
- **Self-updating**: Keep the tool up to date with a single command

## Currently Supported Tools

- Maven

*More tools coming soon!*

## Installation

Install WSDK with a single PowerShell command:

```powershell
irm https://raw.githubusercontent.com/RomainChamb/wsdk/main/install.ps1 | iex
```

This will:
1. Create a `.wsdk` directory in your user profile
2. Download the latest version of WSDK
3. Add WSDK to your PATH environment variable

No administrative privileges are required for installation or usage - WSDK operates entirely within your user profile.

## Usage

### Installing a Tool Version

```powershell 
wsdk install maven <version>
```

This will:
1. Create a directory at `.wsdk/tools/maven/versions/<version>`
2. Set up the necessary environment variables

After running the install command, you need to:
1. Download the tool version from the official website
2. Extract the contents to the created directory

### Listing Available Versions

```powershell
wsdk list maven
```

### Switching Between Versions

```powershell
wsdk use maven <version>
```

### Updating WSDK

```powershell
wsdk update
```

### Getting Help

```powershell
wsdk help
```

## Verification

After installing a tool, verify it's working correctly:

```powershell
mvn --version  # For Maven
```

## Contributing

Contributions are welcome! Here's how you can contribute:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Thanks to all contributors who have helped shape this project
- Inspired by version managers like nvm, sdkman, and others
