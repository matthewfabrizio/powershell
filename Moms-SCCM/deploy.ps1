[CmdletBinding()]
param (
    [Parameter(ParameterSetName='Student',Mandatory)]
    [Parameter(ParameterSetName='Faculty',Mandatory)]
        [string] $Username,
    
    [Parameter(Mandatory=$true)]
        [string] $Domain = "ENTER YOUR DOMAIN HERE AS domain.org",
    
    [Parameter(ParameterSetName='Student')]
        [switch] $Student,

    [Parameter(ParameterSetName='Faculty')]
        [switch] $Faculty,

    [Parameter(Mandatory=$false)]
        [switch] $NoDomain
)

function Write-LogEntry {
    param(
        [parameter(Mandatory=$true, HelpMessage="Value of log entry to be added.")]
        [ValidateNotNullOrEmpty()]
        [string]$Value,

        [parameter(Mandatory=$false, HelpMessage="Name of the log file.")]
        [ValidateNotNullOrEmpty()]
        [string]$global:FileName = "status.log",

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
        if (!$OutNull) { Write-Host $Value }
        Out-File -InputObject "[$(Get-Date -Format g)] => $Value" -Append -NoClobber -Encoding Default -FilePath $LogFilePath -ErrorAction Stop
    }
    catch [System.Exception] {
        Write-Warning -Message "Unable to append log entry to $FileName file"
    }
}

function Install-Chrome() {
    <# Install Google Chrome #>
    Write-LogEntry "Installing Google Chrome"
    $GCCode = Start-Process -FilePath msiexec.exe -ArgumentList "/passive /norestart /i $StandardAppLocation\GoogleChrome.msi /quiet" -Wait -PassThru 
    if ($GCCode.ExitCode -eq 0) { Write-LogEntry "Google Chrome successfully installed`n" }
    else { Write-LogEntry "Google Chrome installation failed`n" }
}

function Install-Firefox() {
    <# Install Firefox #>
    Write-LogEntry "Installing Firefox"
    $FFCode = Start-Process -FilePath "$StandardAppLocation\FirefoxSetup63.0.3.exe" -ArgumentList "-ms" -Wait -PassThru
    if ($FFCode.ExitCode -eq 0) { Write-LogEntry "Firefox successfully installed`n" }
    else { Write-LogEntry "Firefox installation failed`n" }
}

function Install-Adobe() {
    <# Install Acrobat Reader DC #>
    Write-LogEntry "Installing Acrobat Reader"
    $ARCode = Start-Process -FilePath "$StandardAppLocation\Acrobat.exe" -ArgumentList "/sAll" -Wait -PassThru
    if ($ARCode.ExitCode -eq 0) { Write-LogEntry "Adobe Acrobat successfully installed`n" }
    else { Write-LogEntry "Adobe Acrobat installation failed`n" }
}

<#
This application is a reference to the SpecificApps directory.
View the README in that directory.
#>
function Install-CJ() {
    $PUBLIC_DESKTOP = "$env:PUBLIC\Desktop"
    $START_MENU = "$env:ALLUSERSPROFILE\Microsoft\Windows\Start Menu\Programs"
    Write-LogEntry "CJ CONFIG
    Public Desktop : [$PUBLIC_DESKTOP]
    Start Menu     : [$START_MENU]
    " -OutNull

    <# FACES #>
    <# Copy the entire FACES directory to Program Files #>
    Write-LogEntry "Copying FACES to ${env:ProgramFiles(x86)}"
    Copy-Item -Path "$SpecificAppLocation\CJ\FACES" -Destination ${env:ProgramFiles(x86)} -Recurse

    <# Copy the shortcut to the Public Desktop #>
    Write-LogEntry "Copying Shortcut to $PUBLIC_DESKTOP"
    Copy-Item -Path "$SpecificAppLocation\CJ\FACES\FACES.lnk" -Destination $PUBLIC_DESKTOP

    <# Copy the shortcut to the Start Menu #>
    Write-LogEntry "Creating start menu entries at $START_MENU"
    Copy-Item -Path "$SpecificAppLocation\CJ\FACES\FACES.lnk" -Destination $START_MENU

    <# Lessons For Law Enforcement #>
    <# Copy the entire LFLE directory to Program Files #>
    Write-LogEntry "Copying LFLE to $env:ProgramFiles"
    Copy-Item -Path "$SpecificAppLocation\CJ\Lessons_for_Law_Enforcement" -Destination $env:ProgramFiles -Recurse

    <# Copy the shortcut to the Public Desktop #>
    Write-LogEntry "Creating Shortcut to $PUBLIC_DESKTOP"
    Copy-Item -Path "$SpecificAppLocation\Lessons_for_Law_Enforcement\Lessons For Law Enforcement.lnk" -Destination $PUBLIC_DESKTOP

    <# Copy the shortcut to the Start Menu #>
    Write-LogEntry "Creating start menu entries at $START_MENU"
    Copy-Item -Path "$SpecificAppLocation\Lessons_for_Law_Enforcement\Lessons For Law Enforcement.lnk" -Destination $START_MENU
}

function Reg-Mod() {
    Write-LogEntry "Changing registry keys"
    reg load HKLM\DEFAULT c:\users\default\ntuser.dat
    # Advertising ID
    reg add "HKLM\DEFAULT\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" /v Enabled /t REG_DWORD /d 0 /f
    #Delivery optimization, disabled
    reg add "HKLM\DEFAULT\Software\Microsoft\Windows\CurrentVersion\DeliveryOptimization" /v SystemSettingsDownloadMode /t REG_DWORD /d 3 /f
    # Hide system tray icons
    reg add "HKLM\DEFAULT\Software\Microsoft\Windows\CurrentVersion\Explorer" /v EnableAutoTray /t REG_DWORD /d 1 /f
    # Show known file extensions
    reg add "HKLM\DEFAULT\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v HideFileExt /t REG_DWORD /d 0 /f
    # Change default explorer view to my computer
    reg add "HKLM\DEFAULT\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v LaunchTo /t REG_DWORD /d 1 /f
    # Disable most used apps from appearing in the start menu
    reg add "HKLM\DEFAULT\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v Start_TrackProgs /t REG_DWORD /d 0 /f
    # Remove search bar and only show icon
    reg add "HKLM\DEFAULT\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" /v SearchboxTaskbarMode /t REG_DWORD /d 1 /f
    # Show Taskbar on one screen
    reg add "HKLM\DEFAULT\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v MMTaskbarEnabled /t REG_DWORD /d 0 /f
    # Disable Security and Maintenance Notifications
    reg add "HKLM\DEFAULT\SOFTWARE\Microsoft\Windows\CurrentVersion\Notifications\Settings\Windows.SystemToast.SecurityAndMaintenance" /v Enabled /t REG_DWORD /d 0 /f
    # Hide Windows Ink Workspace Button
    reg add "HKLM\DEFAULT\SOFTWARE\Microsoft\Windows\CurrentVersion\PenWorkspace" /v PenWorkspaceButtonDesiredVisibility /t REG_DWORD /d 0 /f
    # Disable Game DVR
    reg add "HKLM\DEFAULT\System\GameConfigStore" /v GameDVR_Enabled /t REG_DWORD /d 0 /f
    reg add "HKLM\DEFAULT\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR" /v AppCaptureEnabled /t REG_DWORD /d 0 /f
    # Show ribbon in File Explorer
    reg add "HKLM\DEFAULT\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Ribbon" /v MinimizedStateTabletModeOff /t REG_DWORD /d 0 /f
    # Hide Taskview button on Taskbar
    reg add "HKLM\DEFAULT\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v ShowTaskViewButton /t REG_DWORD /d 0 /f
    # Hide People button from Taskbar
    reg add "HKLM\DEFAULT\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced\People" /v PeopleBand /t REG_DWORD /d 0 /f
    # Hide Edge button in IE
    reg add "HKLM\DEFAULT\SOFTWARE\Microsoft\Internet Explorer\Main" /v HideNewEdgeButton /t REG_DWORD /d 1 /f
    # Disable suggested apps from appearing in start menu
    reg add "HKLM\DEFAULT\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v SystemPaneSuggestionsEnabled /t REG_DWORD /d 0 /f
    # Turn off Data Collection
    reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" /v AllowTelemetry /t REG_DWORD /d 0 /f
    reg unload HKLM\DEFAULT

    <# Removes the Office 365 Let's Get Started page if you aren't using 365 #>
    Remove-Item -Path "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Office\16.0\Common\OEM" -Recurse -ErrorAction SilentlyContinue
    Remove-Item -Path "HKLM:\SOFTWARE\Microsoft\Office\16.0\Common\OEM" -Recurse -ErrorAction SilentlyContinue
}

function Install-Office($Flag) {
    Write-LogEntry "Repairing .NET Framework"
    $NRCode = Start-Process "$PSScriptRoot\NetRepair\NetFxRepairTool.exe" /p -Wait -PassThru
    if ($NRCode.ExitCode -eq 0) { Write-LogEntry ".Net Repair Tool Installed Successfully`n" }
    else { Write-LogEntry ".NET Repair Tool Installation Failed`n" }
    
    <# Install office based on the ExpressionToRun; use appropriate MSP file #>
    Write-LogEntry "Installing Office for $Flag"
    if ($Flag -eq 'Student') {
        Start-Process "$PSScriptRoot\Office2016\setup.exe" -ArgumentList "/adminfile $PSScriptRoot\Office2016\updates.bak\1_Student_Office2016.MSP" -Wait
    }
    else {
        Start-Process "$PSScriptRoot\Office2016\setup.exe" -ArgumentList "/adminfile $PSScriptRoot\Office2016\updates.bak\Staff.MSP" -Wait
    }
}

function Activate-Office() {
    <# This is a random key I ran into on systems, even if it doesn't exist just try and remove it #>
    cscript "${env:ProgramFiles(x86)}\Microsoft Office\Office16\OSPP.VBS" /unpkey:KHGM9

    <# This automatically activates office with our PK only because setup.exe /admin was configured with it #>
    Write-LogEntry "Activating key..."
    cscript "${env:ProgramFiles(x86)}\Microsoft Office\Office16\OSPP.VBS" /act | Tee-Object -FilePath "$LogFilePath" -Append
}

function Syslog() {
    $Filename = "${NewName}"

    $ErrorActionPreference = 'Silentlycontinue'

    try {
        $Properties = @{
            Asset = $Asset
            Hostname = $NewName
            Manufacturer = (Get-WmiObject -class Win32_ComputerSystem).Manufacturer
            Model = (Get-WmiObject -class Win32_ComputerSystem).Model
            Serial = (Get-WmiObject -class Win32_Bios).SerialNumber
            Edition = (Get-WmiObject Win32_OperatingSystem).Caption
            OS = (Get-WmiObject -Class Win32_OperatingSystem).Version
            Memory = Get-WmiObject -Class Win32_ComputerSystem | Select-Object TotalPhysicalMemory, @{name="GB";expr={[float]($_.TotalPhysicalMemory/1GB)}} | Select-Object -ExpandProperty GB
            MAC = (Get-WmiObject -Class Win32_NetworkAdapterConfiguration -Filter "IPEnabled='True'").MACAddress | Select-Object -First 1
        }

        switch($Properties.OS){
            '10.0.10240' {$Properties.OS="1507"}
            '10.0.10586' {$Properties.OS="1511"}
            '10.0.14393' {$Properties.OS="1607"}
            '10.0.15063' {$Properties.OS="1703"}
            '10.0.16299' {$Properties.OS="1709"}
            '10.0.17134' {$Properties.OS="1803"}
            '10.0.17763' {$Properties.OS="1809"}
        }

        $Results += New-Object PSObject -Property $Properties
    }
    catch {
        Write-LogEntry "Issue with Syslog for $NewName"
    }

    $Results | Select-Object Asset,Hostname,Manufacturer,Model,Serial,Edition,OS,Memory,MAC | Export-Csv -Path Target:${Filename}-$((Get-Date).ToString('MM-dd-yyyy')).csv -NoTypeInformation
    Remove-PSDrive -Name "Target"
}

function Fixed-Configuration() {
    <# Log system information to UNC path via Syslog() #>
    <# 
        This might be the first time you're seeing this weird syntax and I'll explain 
        I chose to call functions this way because I wanted to try something new, but I honestly don't like it...
        BUT, you might think it's cool so you're welcome for showing you something new, see below for more

        This is the equivalent of writing Syslog to call
    #>
    & $Functions[5]

    <# Verify syslog occurred #>
    $SL = [bool](Get-ChildItem "ENTER YOUR UNC REMOTE WORKSTATION AS \\workstation\c$\..." | Where-Object {$_.Name -like "*$NewName*"})
    if ($SL -eq $True) { Write-LogEntry "System Information logged at ENTER YOUR UNC REMOTE WORKSTATION AS \\workstation\c$\..." }
    else { Write-LogEntry "System information failed to log" }

    <# Set TimeZone #>
    Write-LogEntry "Setting timezone to Eastern"
    Set-TimeZone -Name "Eastern Standard Time"

    <# Verify TimeZone #>
    $TZ = Get-TimeZone | Select-Object -ExpandProperty Id
    if ($TZ -eq "Eastern Standard Time") { Write-LogEntry "Timezone set to EST" }
    else { Write-LogEntry "Timezone failed to be set to EST" }

    <# Set Default Layouts XML #>
    Write-LogEntry "Changing Start Menu Layout for all new users"
    Import-StartLayout -LayoutPath "$DefaultTaskbarLayout\DefaultLayouts.xml" -MountPath $env:SystemDrive\ -Verbose

    <# Set Default App Associations #>
    Write-Host "Changing Default App Associations for all new users"
    Dism.exe /online /Import-DefaultAppAssociations:"$DefaultAppAssociations\AppAssociations.xml"

    <# Modify Power Settings #>
    Write-LogEntry "Modifying power settings"
    powercfg /change monitor-timeout-ac 45
    powercfg /change monitor-timeout-dc 45

    powercfg /change standby-timeout-ac 45
    powercfg /change standby-timeout-dc 45
}

function Finalize() {
    <# Net Adapter Binding #>
    $ip6 = "ms_tcpip6"
    $fp_share = "ms_server"

    Get-NetAdapterBinding -ComponentID $ip6,$fp_share | Disable-NetAdapterBinding
    Write-LogEntry "Removed $ip6 and $fp_share from all network interfaces"

    <# Advanced Network Sharing #>
    netsh advfirewall firewall set rule group="Network Discovery" new enable=Yes
    Write-LogEntry "Enabled Network Discovery"

    <# Enable WinRM #>
    Write-LogEntry "Enabling PSRemoting"
    Enable-PSRemoting -Force

    $PSR = [bool](Test-WSMan -ErrorAction SilentlyContinue)
    if ($PSR) { Write-LogEntry "PSRemoting Enabled"}
    else { Write-LogEntry "PSRemoting Disabled" }
}

function Remove-Appx() {
    <# Remove Store Apps #>
    $Apps = @(
        '3D',
        'Advertising',
        'Bing',
        'Cortana',
        'Dell',
        'DesktopApp',
        'Feedback',
        'Get',
        'LinkedIn',
        'Maps',
        'Messaging',
        'NetworkSpeedTest',
        'Office',
        'One',
        'People',
        'Phone',
        'Reality',
        'Remote',
        'Solitaire',
        'Store',
        'Todos',
        'Wallet',
        'Whiteboard',
        'Xbox'
    )

    $Apps | ForEach-Object {
        $AppsRm = $_

        Write-Host "Attempting to remove $_"
        Get-AppxPackage -AllUsers | Where-Object {$_.Name -like "*$AppsRm*"} | Remove-AppxPackage -ErrorAction SilentlyContinue
        Get-AppxProvisionedPackage -Online | Where-Object {$_.DisplayName -like "*$AppsRm*"} | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue
    }
}

function Remove-Dell-Soft() {
    <# Remove Dell Software #>
    $all_dell = Get-WmiObject Win32_Product | Where-Object { $_.Vendor -like "*Dell*" }

    if ($all_dell) { $all_dell.Uninstall() }

    Remove-Item 'C:\Program Files\Dell\' -Recurse -ErrorAction SilentlyContinue
    Remove-Item 'C:\Program Files\Dell Support Center\' -Recurse -ErrorAction SilentlyContinue
}

<#-------------------------------------
            BEGIN
--------------------------------------#>
<# If any .log files exist, remove them #>
if (Test-Path -Path "$PSScriptRoot\Log\*.log") {
    Remove-Item -Path "$PSScriptRoot\Log\*.log"
}

<# Directory Listings #>
$DefaultAppAssociations = "$PSScriptRoot\DefaultAppAssociations"
$DefaultTaskbarLayout   = "$PSScriptRoot\DefaultTaskbarLayout"
$StandardAppLocation    = "$PSScriptRoot\StandardApps"
$SpecificAppLocation    = "$PSScriptRoot\SpecificApps"
$OfficeLocation         = "$PSScriptRoot\Office2016"
$NetRepair              = "$PSScriptRoot\NetRepair"

<# Assign student/faculty switch to ExpressionToRun #>
switch ($PSCmdlet.ParameterSetName) {
    'Student' { $ExpressionToRun = $PSItem }
    'Faculty' { $ExpressionToRun = $PSItem }
}

<# Check for Asset Tag # #>
$Asset = Read-Host "Is there an asset tag for this device? (Y|N)"
if ($Asset -eq 'y') { $Asset = Read-Host -Prompt "What is the asset?" }
else { $Asset = $null }

<# Prompt for new computer hostname #>
if ($NoDomain) { $NewName = (Read-Host -Prompt "What do you want the PC name to be?").ToUpper() }

# $NewName = Read-Host "What do you want the PC name to be?"
Write-LogEntry "Starting Configuration on [$NewName]`n"

<# Verify that you actually want to go through with this #>
if ($NoDomain) {
    Write-Host "Are you sure you want to start configuration on $NewName? [Y/N]" -NoNewline -BackgroundColor Yellow -ForegroundColor Black
    $Verify = Read-Host
}
else {
    Write-Host "Are you sure you want to add $NewName to $Domain [Y/N]" -NoNewline -BackgroundColor Yellow -ForegroundColor Black
    $Verify = Read-Host
}

<# Initialize Menu for Standard App Installation #>
$All     = New-Object System.Management.Automation.Host.ChoiceDescription '&All', 'Installs all applications listed'
$Chrome  = New-Object System.Management.Automation.Host.ChoiceDescription '&Chrome', 'Allows installing Google Chrome'
$Firefox = New-Object System.Management.Automation.Host.ChoiceDescription '&Firefox', 'Allows installing Firefox'
$Adobe   = New-Object System.Management.Automation.Host.ChoiceDescription '&PDF - Adobe', 'Allows installing Adobe Acrobat DC'
$Web     = New-Object System.Management.Automation.Host.ChoiceDescription '&Web - Chrome & Firefox', 'Allows installing Web applications - no PDF'
$Options = [System.Management.Automation.Host.ChoiceDescription[]]($All, $Chrome, $Firefox, $Adobe, $Web)
$StandardResult = $host.ui.PromptForChoice('Applications Installation', 'What applications would you like to install?', $Options, 0)

<# Initialize Menu for Specific App Installation #>
$CJ         = New-Object System.Management.Automation.Host.ChoiceDescription '&Criminal Justice Apps', 'Installs CJ Apps'
$RejectApps = New-Object System.Management.Automation.Host.ChoiceDescription '&None', 'Stops'
$Options    = [System.Management.Automation.Host.ChoiceDescription[]]($RejectApps, $CJ)
$SpecificResult = $host.ui.PromptForChoice('Specific App Installation', 'Where does this computer belong?', $Options, 0)

<# Get user credentials #>
# Throw in a really bad Fallout 3 reference
Write-Host "`nWho..Are You?" -ForegroundColor Yellow
$Cred = (Get-Credential -UserName $Domain\$Username -Message "Enter your password.")
New-PSDrive -Name "Target" -PSProvider "Filesystem" -Root "ENTER YOUR UNC REMOTE WORKSTATION AS \\workstation\c$\..." -Credential (Get-Credential -Credential $Cred) | Out-Null

<# Log basic config settings #>
Write-LogEntry "CONFIG
Asset Tag        : [$Asset]
Applied to       : [$ExpressionToRun]
Configuring      : [$NewName]
Domain           : [$Domain]
App Location     : [$StandardAppLocation]
Specific Apps    : [$SpecificAppLocation]
App Associations : [$DefaultAppAssociations]
Taskbar Layout   : [$DefaultTaskbarLayout]
Office Location  : [$OfficeLocation]
Net Repair       : [$NetRepair]
Log Location     : [$LogFilePath]
" -OutNull

<#-------------------------------------
            PROCESS
--------------------------------------#>
if ($Verify -eq 'y') {
    Write-LogEntry "User selected : [$Verify] - changes initiating" -OutNull
    
    <# Create array of available functions #>
    <#
        Here is where the really weird function calling method starts
        Each function gets loaded with Get-Item whenever it's array index is called
        See the switch statements below
        Basically if you want to call Fixed-Configuration you use 6
        It's weird, but I thought it would be fun because you shouldn't really be using this script as is
    #>
    $Functions = @(
        (Get-Item function:Reg-Mod),
        (Get-Item function:Install-Chrome),
        (Get-Item function:Install-Firefox),
        (Get-Item function:Install-Adobe),
        (Get-Item function:Install-CJ),
        (Get-Item function:Syslog),
        (Get-Item function:Fixed-Configuration),
        (Get-Item function:Remove-Appx),
        (Get-Item function:Remove-Dell-Soft),
        (Get-Item function:Finalize)
    )

    <# Start registry modification #>
    & $Functions[0]

    <# Select default app installations #>
    switch ($StandardResult) {
        0 {
            Write-LogEntry "You chose to install all applications"
            1, 2, 3 | ForEach-Object { & $Functions[$_] }
        }
        1 {
            Write-LogEntry "You chose to only install Google Chrome"
            1 | ForEach-Object { & $Functions[$_] }
        }
        2 {
            Write-LogEntry "You chose to install Firefox only"
            2 | ForEach-Object { & $Functions[$_] }
        }
        3 {
            Write-LogEntry "You chose to install Adobe Acrobat DC only"
            3 | ForEach-Object { & $Functions[$_] }
        }
        4 {
            Write-LogEntry "You chose to install Web applications only"
            1,2 | ForEach-Object { & $Functions[$_] }
        }   
    }

    <# Select specific room applications #>
    switch ($SpecificResult) {
        0 {
            Write-LogEntry "You've opted out of installing any specific apps"
        }
        1 {
            Write-LogEntry "You've opted to install CJ apps"
            4 | ForEach-Object { & $Functions[$_] }
        }
    }

    <# Install Office and Activate #>
    Install-Office $ExpressionToRun
    Activate-Office

    <# Verify office installation #>
    $MO = [bool](Get-ChildItem "${env:ProgramFiles(x86)}\Microsoft Office\Office16\")
    if ($MO) { Write-LogEntry "Office installed at ${env:ProgramFiles(x86)}\Microsoft Office\Office16\"}
    else { Write-LogEntry "Office not installed" }

    <# Apply fixed configuration for system #>
    & $Functions[6]

    <# Remove Appx and Dell programs #>
    7, 8 | ForEach-Object { & $Functions[$_] }

    <# Add PC to domain #>
    if (!$NoDomain) {
        Write-LogEntry "Adding to domain $Domain"
        Add-Computer -DomainName $Domain -NewName $NewName -Credential $Cred -Verbose | Tee-Object -FilePath "$LogFilePath" -Append    
    }
    else { Write-LogEntry "User chose not to add to $Domain" }

    <# Finalize #>
    & $Functions[9]

    <# Restart computer #>
    Restart-Computer -Force
}
else { Write-LogEntry "User selected : [$Verify] - application halted" }