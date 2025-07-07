wsdk : The Sdk Manager for windows

Manage the different sdk you need to develop on windows

Currently supported :

- maven

How to install :
```powershell
irm https://raw.githubusercontent.com/RomainChamb/wsdk/main/install.ps1 | iex
```

How to use :
```powershell 
wsdk install maven <version>
```
It will create .wsdk/tools/maven/versions/<version>

In this folder extract the content of the tools version that you have previously download on the maven website.

Check that the maven version is now up to date by running
```powershell
mvn --version
```

