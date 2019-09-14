<h3 align="center">Get-ACDCPowerCfg</h3>

<div align="center">

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](../LICENSE)

</div>

## About
Gets the power values of AC / DC from the active power scheme.
Values from SCHEME_BALANCED are typical in most settings.

## Getting Started
Since this is a small script, a simple `git clone` will get you a copy of the script up and running on your local machine for development and testing purposes.

## Usage

### Modifying Script Output

To modify what is displayed, edit the bottom three function calls ranging from lines 66-68 (see below).

### Getting Help On powercfg.exe
There are two commands that can get you started with changing what the script outputs. They are shown within the Help parameter.

```ps
.\Get-ACDCPowerCfg.ps1 -Help
```

## Future Implementations

- [ ] Parameters for Power Scheme GUID and Subgroup GUID

## Resources

|   |
|---|
| [Parameters](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_functions_advanced_parameters?view=powershell-6) |
| [powercfg.exe](https://docs.microsoft.com/en-us/windows-hardware/design/device-experiences/powercfg-command-line-options) |
| [regex](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_regular_expressions?view=powershell-6) |
| [[System.Timespan]](https://docs.microsoft.com/en-us/dotnet/api/system.timespan?view=netframework-4.8) |
| [[System.Convert]](https://docs.microsoft.com/en-us/dotnet/api/system.convert?view=netframework-4.8)
