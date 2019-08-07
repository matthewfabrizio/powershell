# Frozone

Frozone.ps1 is a quick inventory scanning tool built with PowerShell. It is called Frozone because it's meant to be quick and let's be honest...ain't no one quicker than my boy Frozone.

This script is still a WIP and may contain some inconsistency.

# Scanning

There are a couple parts to this script that are pretty neat and those are mainly the different ways to scan.

## Hostname Scanning

There are two methods that are similar (`Single Scan`, `Loop Scan`). They do what the name implies. The interesting portion is how they are coded (which looks kinda messy, but this is WIP).

```ps
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
```

## AD Query Scanning

A very useful function of this script is the ability to scan Active Directory for computer inventory, which can be seen below.

The query is built off of a simple wildcard match with the intent that a script invoker searches for the beginning of the device hostname. This is very useful for scanning more than a few devices at a time.

For example, if you want to scan 12 devices all starting with the name `zStation`, it can easily be done with an AD query (provided you have these devices registered in AD).

```ps
'a' { 
            $ADFilter = Read-Host "What computer would you like to search for?"
            $ADQuery = (Get-ADComputer -Filter "Name -like '$ADFilter*'" | Select-Object -ExpandProperty Name) -join ","
            $ADQuery = $ADQuery.Split(",").Trim(" ")
            Local-Scan -ComputerName $ADQuery
            exit
        }
```

## Clipping

The absolute most useful part of this script is the automation of `Set-Clipboard`. Once a device is scanned, specific information is copied to the clipboard in Excel tab (`t) based format. Regardless if you scan one device or 10, they are all ready to be copied into however many rows you need.

## Logging

There is a logging feature provided in the script. It has a semi decent use-case, but to be honest it's just there for the extra benefit of logging what devices were/weren't successfully scanned. The `status.log` file is discarded and updated every time the script is invoked.

## Debugging

Recently, a more defined approach to debugging was added specifically targeting specific PowerShell invocation information. Two nice features of this approach are easier to read error messages, as well as the line number that failed (see below).

```ps
catch [System.Exception] {
            Write-Host "[ERROR] : Device [$Computer] " -ForegroundColor Red -NoNewline
            "{0}" -f $_.Exception.Message
            "`nException caught on line {0}" -f $_.InvocationInfo.ScriptLineNumber
            $File = Split-Path $MyInvocation.ScriptName -Leaf
            (Get-Content $File -TotalCount $_.InvocationInfo.ScriptLineNumber)[-1]
        }
```