function Write-LogEntry {
    param(
        [parameter(Mandatory=$true, HelpMessage="Value of log entry to be added.")]
        [ValidateNotNullOrEmpty()]
        [string] $Value,

        [parameter(Mandatory=$false, HelpMessage="Name of the log file.")]
        [ValidateNotNullOrEmpty()]
        [string] $FileName = "status.log",

        [Parameter(Mandatory=$false, HelpMessage="Prevents logging to STDOUT")]
        [switch] $OutNull
    )
    
    <# If no Log directory exists, create it #>
    if (!(Test-Path "$PSScriptRoot\Log" -PathType Container)) {
        New-Item -Path "$PSScriptRoot" -Name "Log" -ItemType Directory | Out-Null
    }

    <# Determine log file location #>
    $global:LogFilePath = Join-Path -Path "$PSScriptRoot" -ChildPath "Log\$($FileName)"

    <# Add value to log file #>
    try {
        if (!$OutNull) { Write-Host $Value -ForegroundColor Green }
        Out-File -InputObject "[$(Get-Date -Format g)] => $Value" -Append -NoClobber -Encoding Default -FilePath $LogFilePath -ErrorAction Stop
    }
    catch [System.Exception] {
        Write-Warning -Message "Unable to append log entry to $FileName file"
    }
}

function Show-Menu {
    Clear-Host

    Write-Host "`n=========== MENU ==========="
  
    Write-Host "[A]: AD Query Scan"
    Write-Host "[L]: Loop Scan"
    Write-Host "[S]: Single Scan"
    Write-Host "[Q]: Quit`n"

    $Selection = Read-Host "Select a menu option"

    return $Selection;
}

function Local-Scan() {
    [CmdletBinding()]
        param (
            [string[]] $ComputerName
    )
    
    Write-Output $Null | Set-Clipboard
    $Online = [System.Collections.ArrayList]::New()

    foreach ($Computer in $ComputerName.ToUpper()) {
        Write-Progress "Pinging $Computer"
        if ((Test-Connection -ComputerName $Computer -Count 1 -Quiet)) {
            Write-LogEntry "Connection to [$Computer] successful."
            [Void]$Online.Add($Computer)
        }
        else { Write-Host "`n$Computer unavailable." -ForegroundColor Red }
    }

    $LocalArray = [System.Collections.ArrayList]::New()

    foreach ($Computer in $Online) {
        try {
            $Win32_OperatingSystem = (Get-WmiObject -ComputerName $Computer -Class Win32_OperatingSystem -ErrorAction Stop)
            $Win32_ComputerSystem  = (Get-WmiObject -ComputerName $Computer -Class Win32_ComputerSystem -ErrorAction Stop)
            $Win32_Bios            = (Get-WmiObject -ComputerName $Computer -Class Win32_Bios -ErrorAction Stop)
            $Win32_PhysicalMemory  = (Get-WmiObject -ComputerName $Computer -Class Win32_PhysicalMemory -ErrorAction Stop)
            $Win32_NetworkAdapterConfiguration = (Get-WmiObject -ComputerName $Computer -Class Win32_NetworkAdapterConfiguration | Where-Object {$_.Description -notmatch 'wan miniport|microsoft isatap adapter|bluetooth|juniper|ras async adapter|virtual|apple|miniport|tunnel|debug|advanced-n|wireless-n|ndis'} -ErrorAction Stop)

            <# Error on laptop devices with IP and Subnet #>
            $Hostname     = $Win32_OperatingSystem.CSName
            $Manufacturer = $Win32_ComputerSystem.Manufacturer
            $Model        = $Win32_ComputerSystem.Model
            $Serial       = $Win32_Bios.SerialNumber
            $Edition      = $Win32_OperatingSystem.Caption
            $OS           = $Win32_OperatingSystem.Version
            $Memory       = $Win32_PhysicalMemory | Measure-Object -Property Capacity -Sum | ForEach-Object {"{0:N2}" -f ([math]::round(($_.Sum / 1GB),2))}
            $IP           = $Win32_NetworkAdapterConfiguration.IPAddress[0]
            $Domain       = $Win32_NetworkAdapterConfiguration.DNSDomain
            $MAC          = $Win32_NetworkAdapterConfiguration.MACAddress
            $Subnet       = $Win32_NetworkAdapterConfiguration.IPSubnet[0]
            $Age          = $Win32_Bios
            $ReimageDate  = $Win32_OperatingSystem

            <# AD Queries #>
            # $Hostname = Get-ADComputer $Computer -Properties CN | Select-Object -ExpandProperty CN
            # $OS = Get-ADComputer $Computer -Properties OperatingSystem | Select-Object -ExpandProperty OperatingSystem
            # $IP = Get-ADComputer $Computer -Properties IPv4Address | Select-Object -ExpandProperty IPv4Address

            switch($OS){
                '10.0.10240' {$OS="1507"}
                '10.0.10586' {$OS="1511"}
                '10.0.14393' {$OS="1607"}
                '10.0.15063' {$OS="1703"}
                '10.0.16299' {$OS="1709"}
                '10.0.17134' {$OS="1803"}
                '10.0.17763' {$OS="1809"}
                '10.0.18362' {$OS="1903"}
            }

            $Manufacturer = [string]$Manufacturer.replace("Inc.","")
            $Make = $Manufacturer + $Model

            if ($Model -like '*Optiplex*') { $Type = "Desktop" } 
            else { $Type = "Laptop" }

            $Age = (New-TimeSpan -Start ($Age.ConvertToDateTime($Age.ReleaseDate).ToShortDateString()) -End $(Get-Date)).Days / 365
            $ReimageDate = ($ReimageDate.ConvertToDateTime($ReimageDate.InstallDate).ToString("MM/dd/yyyy"))

            <# Calculate Decimal Age to Date #>
            $CalculatedAge = ($Age * 365.25)
            $CalculatedAge = (Get-Date).AddDays(-$CalculatedAge).ToString("MM/dd/yyyy")

            $Properties = [PSCustomObject]@{
                Hostname = $Hostname
                Device = $Make
                Type = $Type
                Serial = $Serial
                Edition = $Edition
                OS = $OS
                Memory = $Memory
                IP = $IP
                Domain = $Domain
                MAC = $MAC
                Subnet = $Subnet
                DecimalAge = $Age
                Age = $CalculatedAge
                Reimaged = $ReimageDate
            }

            [Void]$LocalArray.Add($Properties)

            <# Select properties for Excel inventory sheet #>
            ($Properties | Select-Object Device,Type,Hostname,Serial,Edition,OS,Age,Reimaged | ForEach-Object {
                $Age = "=ROUND(YEARFRAC(`"$CalculatedAge`", TODAY()), 2)"
                $_.Device
                $_.Type
                $_.Hostname
                $_.Serial
                $_.Edition
                $_.OS
                $Age
                $_.Reimaged
            }) -join "`t" | Set-Clipboard -Append
        }
        # TODO : fix this mess
        catch [System.Exception] {
            Write-Host "[ERROR] : Device [$Computer] " -ForegroundColor Red -NoNewline
            "{0}" -f $_.Exception.Message
            "`nException caught on line {0}" -f $_.InvocationInfo.ScriptLineNumber
            $File = Split-Path $MyInvocation.ScriptName -Leaf
            (Get-Content $File -TotalCount $_.InvocationInfo.ScriptLineNumber)[-1]
        }
    }

    if (!($Null -eq $(Get-Clipboard))) { Get-Clipboard | ForEach-Object { Write-LogEntry $_ -OutNull } }
    
    <# Spicy STDOUT #>
    $LocalArray
}

Write-LogEntry "Starting Inventory Script; Generating log file..." -OutNull

<# If any .log files exist, remove them #>
if (Test-Path -Path "$PSScriptRoot\Log\*.log") {
    Remove-Item -Path "$PSScriptRoot\Log\*.log"
}

<# Immediately stop any errors in the script #>
# Prevents specific exception handling; use Common Parameter
# $ErrorActionPreference = 'Stop'

do {
    <# Get the selection from Show-Menu; switch on that choice #>
    $Choice = Show-Menu
    switch ($Choice) {
        <# Prompt for AD search terms - only starting characters #>
        'a' { 
            $ADFilter = Read-Host "What computer would you like to search for?"
            $ADQuery = (Get-ADComputer -Filter "Name -like '$ADFilter*'" | Select-Object -ExpandProperty Name) -join ","
            $ADQuery = $ADQuery.Split(",").Trim(" ")
            Local-Scan -ComputerName $ADQuery
            exit
        }
        <# [l|L] Prompt for a computer to scan; exit on SIGINT #>
        <# [s|S] Prompt for a computer to scan; exit once complete #>
        { @('l','s') -contains $_ } {
            $hostnameExists = $false
            while (!$hostnameExists) {
                Write-Host "`nType 'stop|Stop|Ctrl+c' to exit.`n" -ForegroundColor Yellow
                $Computers = Read-Host "What computer would you like to scan?"
                if ($Computers -contains 'stop') { exit }
                $Computers = $Computers.Split(",").Trim(" ")
                Local-Scan -ComputerName $Computers
                if ($_ -eq 's') { $hostnameExists=$true }
            }
        }
        <# Log user quit prompt; Clear the screen; Exit the application #>
        'q' { Write-LogEntry "User terminated application with [$_]" -OutNull; Clear-Host; exit }
        default { Write-Host "Invalid menu choice" -ForegroundColor Red }  
    }
} while ($Choice -eq 'q')