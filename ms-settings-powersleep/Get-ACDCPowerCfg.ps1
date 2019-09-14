<#
.SYNOPSIS
Get power values (AC / DC)

.DESCRIPTION
Get the power values of AC / DC from the power schemes.
Values from SCHEME_BALANCED are typical in most settings.

.PARAMETER Help
Simple help information about powercfg.exe switches.

.EXAMPLE
.\Get-ACDCPowerSettings.ps1

.NOTES
===========================================================================
     Created on:   	9/9/2019
     Updated on:    9/14/19
	 Author:    	Matthew Fabrizio
	 Organization: 	*** 
	 Filename:     	Get-ACDCPowerCfg.ps1
===========================================================================
#>
param(
    # Prints help information (specifically some powercfg switches to get started)
    [Parameter(Mandatory=$false)]
    [switch]
    $Help
)

function Get-Help(){
    "
    AC = power cable
    DC = battery power.

    Power Scheme Aliases
        powercfg.exe /aliases

    Existing Power Schemes (includes active scheme)
        powercfg.exe /list
    "
}

function Get-ACDCValue ($Name,$Data) {  
    # Set regex pattern of possible hex values
    $HexNumber = "0x[0-9a-f]{8}"

    # Take the powercfg query GUIDs and look for the word Index, which indicates the two hex AC/DC values
    # powercfg output needs to be stored in a variable for parsing the output.
    $Values = $Data -split "`n" | Where-Object { $PSItem -Like '*Index*' -and $PSItem -match $HexNumber }
    if ($Values.Count -ne 2) { throw "Incorrect number of values found ($($Values.Count)), there should be 2 values" }

    # Store the AC/DC values respectively
    $AC, $DC = $Values -replace ".*($HexNumber)\s*", '$1' -replace "^0x"

    # Get the timespan in minutes of the converted hex value seconds to octal; or something along those lines
    $AC = ([System.TimeSpan]::FromSeconds(([System.Convert]::ToInt64($AC, 16)))).TotalMinutes
    $DC = ([System.TimeSpan]::FromSeconds(([System.Convert]::ToInt64($DC, 16)))).TotalMinutes

    # Output : Name => AC[minutes] DC[minutes]
    "{0,-9} => AC[{1:d3} min] DC[{2:d3} min]" -f $Name, [int]$AC, [int]$DC
}

if($Help) { Get-Help; exit }

# powercfg /query will give you information on SCHEME_BALANCED (alias), etc
Get-ACDCValue -Name "Hard Disk" -Data (powercfg.exe /Q SCHEME_BALANCED SUB_DISK)
Get-ACDCValue -Name "Sleep"     -Data (powercfg.exe /Q SCHEME_BALANCED SUB_SLEEP STANDBYIDLE)
Get-ACDCValue -Name "Screen"    -Data (powercfg.exe /Q SCHEME_BALANCED SUB_VIDEO VIDEOIDLE)