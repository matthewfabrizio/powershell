<#
.SYNOPSIS  
Create users in Active Directory from a CSV file.

.DESCRIPTION
Pass in a CSV defining a user sheet (i.e. student, faculty, etc.) and let the script do the rest.

.EXAMPLE
.\Add-CatUser.ps1

.NOTES
Author  : Matthew Fabrizio
Project : Add-CatUser
Version : 1.0.0

.LINK
    https://github.com/matthewfabrizio/powershell/
#>
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

function Modify-Username($First, $Username, $Index) {
    return $Username += $First[$Index]
}

function Check-User($Username) {
    Write-Host "`nChecking Username : [$Username]"
    $usernameIsValid = $false
    $Index = 1

    while (!$usernameIsValid) {
        if (Get-ADUser -LDAPFilter "(SAMAccountName=$Username)") {
            $Username = Modify-Username $First $Username $Index
            $Index++
        }
        else {
            Write-Host "Valid Username    : [$Username]`n" -ForegroundColor Green
            $usernameIsValid = $true
        }
    }

    return $Username
}

Write-LogEntry "
=========================
Starting AD User Creation
=========================
"

$CSVSheet = Get-ChildItem "$PSScriptRoot\user_sheets\*" | ForEach-Object { $_.FullName } | Out-GridView -Title "User Sheets" -PassThru

if (Test-Path "$PSScriptRoot\users.csv" -PathType Leaf) {
    Remove-Item "$PSScriptRoot\users.csv"
    Write-LogEntry -Value "Removed users.csv from $PSScriptRoot"
}
if (Test-Path "$PSScriptRoot\Log\*.log" -PathType Leaf) {
    Remove-Item "$PSScriptRoot\Log\*.log"
    Write-LogEntry -Value "Removed all log entries" -OutNull
}
if (!(Test-Path "$PSScriptRoot\Log\" -PathType Container)) {
    New-Item -Path "$PSScriptRoot\" -Name "Log" -ItemType Directory
    Write-LogEntry -Value "Created Log directory at $PSScriptRoot" -OutNull
}

<#--------------------
    Get the new users
--------------------#>
$Users = Import-Csv "$UserSheet" | Sort-Object Location,Course
$Info = Get-Content "$PSScriptRoot\info.json" | ConvertFrom-Json
$UserSheet = @()

Write-LogEntry -Value "CONFIG
User Sheet  : $CSVSheet
" -OutNull

$Users | ForEach-Object {
    foreach ($user in $_) {
        <#--------------------
            Check if there is a user with the exact same first and last name
        --------------------#>
        if (Get-ADUser -Filter "GivenName -eq '$($user.First)' -and Surname -eq '$($user.Last)'") {
            Write-LogEntry -Value "User [$($user.First) $($user.Last)] already exists" -FileName "existing-users.csv"
            break 
        }
        
        <#--------------------
            CSV Info
        --------------------#>
        $Building = $user.Building
        $First = $user.First.tolower()
        $Last = $user.Last.tolower()
        $GradYear = $user.GradYear
        $Course = $user.Course

        <#--------------------
            CSV Modifications
        --------------------#>
        $FullName =  '{0} {1}' -f $First, $Last; $FullName = (Get-Culture).TextInfo.ToTitleCase($FullName)
        $FirstName = (Get-Culture).TextInfo.ToTitleCase($First)
        $LastName = (Get-Culture).TextInfo.ToTitleCase($Last)
        
        $Password = $First.toupper().substring(0,2) + $Last.tolower().substring(0,2) + (Get-Random -Minimum 1000 -Maximum 9999)

        $Username = $Last + $First[0]
        $Username = Check-User $Username

        $UserData = @{
            'FullName' = $FullName
            'Username'  = $Username
            'Password'  = $Password
            'Course'    = $Course
        }

        $UserSheet += New-Object PSObject -Property $UserData
        
        <#--------------------
            AD Information
        --------------------#>
        # CHANGE : If different building name, change here
        # CHANGE : If more than one building, use elif; update JSON
        if ($Building -eq "Building1") {
            $ProfilePath    = "$($Info.Buildings.Building1.ProfilePath)\$GradYear\$Username"
            $City           = "$($Info.Buildings.Building1.City)"
            $Address        = "$($Info.Buildings.Building1.Address)"
            $Zip            = "$($Info.Buildings.Building1.Zip)"
        }
        else {
            $ProfilePath    = "$($Info.Buildings.Building2.ProfilePath)\$GradYear\$Username"
            $City           = "$($Info.Buildings.Building2.City)"
            $Address        = "$($Info.Buildings.Building2.Address)"
            $Zip            = "$($Info.Buildings.Building2.Zip)"
        }

        <# Fixed JSON information #>
        $Email      = "$Username" + "@" + "$($Info.Static.EmailExtension)"
        $Title      = "$($Info.Static.Title)"
        $Company    = "$($Info.Static.Company)"
        $State      = "$($Info.Static.State)"
        $Country    = "$($Info.Static.Country)"

        # OU Information
        $DomainDN = (Get-ADDomain).DistinguishedName
        $UserRoot = $Info.Static.UserOU_Base + " $Building,$DomainDN"
        $UserOU = "OU=$GradYear,$UserRoot"

        if (!(Get-ADOrganizationalUnit -Filter "DistinguishedName -eq '$UserOU'")) {
            try {
                Write-Host "The user OU [$($UserOU)] does not exist."
                Write-Host "Creating OU [$($GradYear)] in [$($UserRoot)]"
                New-ADOrganizationalUnit -Name $GradYear -Path $UserRoot
            }
            catch {
                Write-Host "Failed to create OU [$UserOU]"
                exit
            }
        }

        <#--------------------
            The big ol splat
        --------------------#>
        $NewUserParams = @{
            'Name' = '{0} {1}' -f "$FirstName", "$LastName"
            'GivenName' = "$FirstName"
            'Surname' = "$LastName"
            'DisplayName' = $FullName
            'EmailAddress' = $Email
            'SamAccountName' = $Username
            'UserPrincipalName' = $Email
            'AccountPassword' = (ConvertTo-SecureString $Password -AsPlainText -Force)
            'Path' = $UserOU
            'City' = $City
            'Company' = $Company
            'Description' = "$($Info.Descriptions.$Course)"
            'StreetAddress' = $Address
            'State' = $State
            'PostalCode' = $Zip
            'Country' = $Country
            'PasswordNeverExpires' = $true
            'ChangePasswordAtLogon' = $false
            'ProfilePath' = $ProfilePath
            'Title' = $Title
            'Enabled' = $true
        }

        <#--------------------
            Modify AD
        --------------------#>
        # Splataroo
        New-ADUser @NewUserParams -WhatIf

        Add-ADGroupMember -Members $Username -Identity $($Info.Groups.$Course) -WhatIf
        'Adding [{0}] to [{1}]' -f "$Username", "$($Info.Groups.$Course)"
    }
}

$UserSheet | Select-Object FullName,Username,Password,Course | Export-Csv -NoTypeInformation "$PSScriptRoot\users.csv"
Write-Host "`nYou can view created users at $PSScriptRoot\users.csv" -ForegroundColor Green