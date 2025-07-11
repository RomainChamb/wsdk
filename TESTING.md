# Testing Strategy for WSDK

This document outlines a comprehensive testing strategy for the WSDK project, including how to set up and run tests locally and in a CI pipeline.

## Table of Contents

1. [Testing Framework](#testing-framework)
2. [Test Categories](#test-categories)
3. [Local Testing Setup](#local-testing-setup)
4. [CI Pipeline Setup](#ci-pipeline-setup)
5. [Example Test Cases](#example-test-cases)
6. [Running Tests](#running-tests)
7. [Test Maintenance](#test-maintenance)

## Testing Framework

For WSDK, we recommend using [Pester](https://pester.dev/) - the ubiquitous testing and mocking framework for PowerShell. Pester provides a BDD-style testing syntax that makes tests readable and maintainable.

### Why Pester?

- Native PowerShell testing framework
- Active community and development
- Supports mocking for isolation testing
- Built-in code coverage reporting
- Compatible with CI/CD pipelines
- Supports both PowerShell 5.1 and PowerShell Core

## Test Categories

We'll organize tests into the following categories:

1. **Unit Tests**: Test individual functions in isolation
2. **Integration Tests**: Test interactions between components
3. **Functional Tests**: Test end-to-end workflows
4. **Installation Tests**: Verify installation process works correctly

## Local Testing Setup

### Step 1: Install Pester

```powershell
# Install the latest version of Pester
Install-Module -Name Pester -Force -SkipPublisherCheck
```

### Step 2: Create Test Directory Structure

```
wsdk/
├── tests/
│   ├── unit/
│   │   ├── wsdk.tests.ps1
│   │   └── install-tools.tests.ps1
│   ├── integration/
│   │   └── tool-installation.tests.ps1
│   ├── functional/
│   │   └── end-to-end.tests.ps1
│   └── installation/
│       └── install.tests.ps1
└── tools/
    └── test-helpers.ps1
```

### Step 3: Create Test Helper Functions

Create a `tools/test-helpers.ps1` file with common testing utilities:

```powershell
function New-TestEnvironment {
    param(
        [string]$TestName
    )
    
    # Create isolated test environment
    $TestDir = Join-Path $TestDrive $TestName
    New-Item -ItemType Directory -Path $TestDir -Force
    
    return $TestDir
}

function Remove-TestEnvironment {
    param(
        [string]$TestDir
    )
    
    # Clean up test environment
    if (Test-Path $TestDir) {
        Remove-Item -Path $TestDir -Recurse -Force
    }
}
```

## CI Pipeline Setup

### Step 1: Create GitHub Actions Workflow

Create a file at `.github/workflows/test.yml`:

```yaml
name: Test WSDK

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: windows-latest
    
    steps:
    - uses: actions/checkout@v2
    
    - name: Install Pester
      shell: pwsh
      run: |
        Install-Module -Name Pester -Force -SkipPublisherCheck
    
    - name: Run Tests
      shell: pwsh
      run: |
        $config = New-PesterConfiguration
        $config.Run.Path = "./tests"
        $config.Output.Verbosity = "Detailed"
        $config.CodeCoverage.Enabled = $true
        $config.CodeCoverage.Path = "./*.ps1", "./install-tools/*.ps1"
        $config.CodeCoverage.OutputFormat = "JaCoCo"
        $config.CodeCoverage.OutputPath = "./coverage.xml"
        
        Invoke-Pester -Configuration $config
    
    - name: Upload Test Results
      uses: actions/upload-artifact@v2
      with:
        name: test-results
        path: ./coverage.xml
```

### Step 2: Set Up Branch Protection Rules

In GitHub repository settings:

1. Go to Settings > Branches
2. Add rule for `main` branch
3. Require status checks to pass before merging
4. Require the "test" workflow to pass

## Example Test Cases

### Unit Test Example (wsdk.tests.ps1)

```powershell
BeforeAll {
    # Import the module or dot source the script
    . $PSScriptRoot/../../wsdk.ps1
}

Describe "Switch-Version function" {
    BeforeEach {
        # Set up test environment
        $TestDir = New-TestEnvironment -TestName "SwitchVersionTest"
        $env:HomeDir = $TestDir
        
        # Create necessary directories
        New-Item -ItemType Directory -Path "$TestDir\.wsdk\tools\maven\versions\3.8.6" -Force
        New-Item -ItemType Directory -Path "$TestDir\.wsdk\current" -Force
    }
    
    It "Should switch to the specified version" {
        # Mock the cmd call for creating junction
        Mock cmd { } -ParameterFilter { $args[0] -eq "/c" -and $args[1] -eq "mklink" }
        
        # Call the function
        Switch-Version -Tool "maven" -Version "3.8.6"
        
        # Verify the mock was called with expected parameters
        Should -Invoke cmd -ParameterFilter {
            $args[0] -eq "/c" -and 
            $args[1] -eq "mklink" -and 
            $args[2] -eq "/J" -and 
            $args[3] -like "*\.wsdk\current\maven" -and 
            $args[4] -like "*\.wsdk\tools\maven\versions\3.8.6"
        }
    }
    
    AfterEach {
        # Clean up test environment
        Remove-TestEnvironment -TestDir $TestDir
    }
}
```

### Integration Test Example (tool-installation.tests.ps1)

```powershell
BeforeAll {
    # Import the module or dot source the scripts
    . $PSScriptRoot/../../wsdk.ps1
    . $PSScriptRoot/../../install-tools/install-maven.ps1
}

Describe "Maven Installation Integration" {
    BeforeEach {
        # Set up test environment
        $TestDir = New-TestEnvironment -TestName "MavenInstallTest"
        $env:HomeDir = $TestDir
        
        # Create necessary directories
        New-Item -ItemType Directory -Path "$TestDir\.wsdk\tools\maven\versions" -Force
        New-Item -ItemType Directory -Path "$TestDir\.wsdk\current" -Force
    }
    
    It "Should set up environment variables correctly" {
        # Mock environment variable setting
        Mock [Environment]::SetEnvironmentVariable { } -ParameterFilter { $Name -eq "MAVEN_HOME" }
        Mock [Environment]::SetEnvironmentVariable { } -ParameterFilter { $Name -eq "M2_HOME" }
        Mock [Environment]::SetEnvironmentVariable { } -ParameterFilter { $Name -eq "Path" }
        
        # Call the installation script
        & $PSScriptRoot/../../install-tools/install-maven.ps1 -Version "3.8.6"
        
        # Verify environment variables were set
        Should -Invoke [Environment]::SetEnvironmentVariable -ParameterFilter { 
            $Name -eq "MAVEN_HOME" -and 
            $Value -like "*\.wsdk\current\maven" 
        }
        
        Should -Invoke [Environment]::SetEnvironmentVariable -ParameterFilter { 
            $Name -eq "M2_HOME" -and 
            $Value -like "*\.wsdk\current\maven\bin" 
        }
    }
    
    AfterEach {
        # Clean up test environment
        Remove-TestEnvironment -TestDir $TestDir
    }
}
```

### Functional Test Example (end-to-end.tests.ps1)

```powershell
Describe "End-to-End Workflow" {
    BeforeEach {
        # Set up test environment
        $TestDir = New-TestEnvironment -TestName "E2ETest"
        $env:HomeDir = $TestDir
        
        # Create necessary directories and files
        New-Item -ItemType Directory -Path "$TestDir\.wsdk\tools\maven\versions\3.8.6\bin" -Force
        New-Item -ItemType Directory -Path "$TestDir\.wsdk\current" -Force
        
        # Create mock maven executable
        $MockMvn = @"
@echo off
echo Maven 3.8.6
"@
        Set-Content -Path "$TestDir\.wsdk\tools\maven\versions\3.8.6\bin\mvn.cmd" -Value $MockMvn
    }
    
    It "Should install and use Maven correctly" {
        # Mock environment path to include test directory
        $OriginalPath = $env:Path
        $env:Path = "$TestDir\.wsdk;$env:Path"
        
        try {
            # Run the install command
            & $PSScriptRoot/../../wsdk.ps1 -Command "install" -Tool "maven" -Version "3.8.6"
            
            # Run the use command
            & $PSScriptRoot/../../wsdk.ps1 -Command "use" -Tool "maven" -Version "3.8.6"
            
            # Verify the tool is accessible
            $ToolPath = "$TestDir\.wsdk\current\maven\bin\mvn.cmd"
            Test-Path $ToolPath | Should -Be $true
            
            # Verify the environment is set up correctly
            $env:MAVEN_HOME | Should -Be "$TestDir\.wsdk\current\maven"
            $env:M2_HOME | Should -Be "$TestDir\.wsdk\current\maven\bin"
        }
        finally {
            # Restore original path
            $env:Path = $OriginalPath
        }
    }
    
    AfterEach {
        # Clean up test environment
        Remove-TestEnvironment -TestDir $TestDir
    }
}
```

## Running Tests

### Running Tests Locally

```powershell
# Run all tests
Invoke-Pester -Path ./tests

# Run specific test category
Invoke-Pester -Path ./tests/unit

# Run with code coverage
$config = New-PesterConfiguration
$config.Run.Path = "./tests"
$config.CodeCoverage.Enabled = $true
$config.CodeCoverage.Path = "./*.ps1", "./install-tools/*.ps1"
Invoke-Pester -Configuration $config
```

### Running Tests in CI

Tests will run automatically on push to main branch or when creating a pull request, based on the GitHub Actions workflow configuration.

## Test Maintenance

### Best Practices

1. **Keep tests independent**: Each test should be able to run in isolation
2. **Use mocking for external dependencies**: Avoid actual network calls or file system operations
3. **Clean up after tests**: Remove any test artifacts or state changes
4. **Use descriptive test names**: Tests should clearly indicate what they're testing
5. **Update tests when code changes**: Tests should evolve with the codebase
6. **Aim for high code coverage**: Target at least 80% code coverage
7. **Test edge cases**: Include tests for error conditions and boundary cases

### Continuous Improvement

1. Review test results regularly
2. Add new tests for new features
3. Refactor tests as needed to improve maintainability
4. Monitor test performance and optimize slow tests

By following this testing strategy, the WSDK project will maintain high quality and reliability as it evolves.
