function Get-Menu {
    [System.Console]::Clear()

    [System.Console]::WriteLine("`n" + "----------- MENU -----------")
    [System.Console]::WriteLine("[1] : Create Task")
    [System.Console]::WriteLine("[2] : Complete Task")
    [System.Console]::WriteLine("[3] : Search Tasks")
    [System.Console]::WriteLine("[Q] : Quit")
    [System.Console]::WriteLine("----------------------------" + "`n")
}

function Get-SubMenu {
    [System.Console]::Clear()

    [System.Console]::WriteLine("`n" + "----------- MENU -----------")
    [System.Console]::WriteLine("[1] : Show Newest")
    [System.Console]::WriteLine("[2] : Show Oldest")
    [System.Console]::WriteLine("[3] : Show Completed")
    [System.Console]::WriteLine("[4] : Show Due Date")
    [System.Console]::WriteLine("[Q] : Quit")
    [System.Console]::WriteLine("----------------------------" + "`n")
}

function DatePicker() {
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    $form = New-Object Windows.Forms.Form -Property @{
        StartPosition = [Windows.Forms.FormStartPosition]::CenterScreen
        Size          = New-Object Drawing.Size 243, 230
        Text          = 'Select a Date'
        Topmost       = $true
    }

    $calendar = New-Object Windows.Forms.MonthCalendar -Property @{
        ShowTodayCircle   = $false
        MaxSelectionCount = 1
    }
    $form.Controls.Add($calendar)

    $OKButton = New-Object Windows.Forms.Button -Property @{
        Location     = New-Object Drawing.Point 38, 165
        Size         = New-Object Drawing.Size 75, 23
        Text         = 'OK'
        DialogResult = [Windows.Forms.DialogResult]::OK
    }
    $form.AcceptButton = $OKButton
    $form.Controls.Add($OKButton)

    $CancelButton = New-Object Windows.Forms.Button -Property @{
        Location     = New-Object Drawing.Point 113, 165
        Size         = New-Object Drawing.Size 75, 23
        Text         = 'Cancel'
        DialogResult = [Windows.Forms.DialogResult]::Cancel
    }
    $form.CancelButton = $CancelButton
    $form.Controls.Add($CancelButton)

    $result = $form.ShowDialog()

    if ($result -eq [Windows.Forms.DialogResult]::OK) {
        $date = $calendar.SelectionStart
        return $($date.ToString("yyyy-MM-dd"))
    }
}

function Create-Task() {
    $NewTask = Read-Host "New Task"
    # TODO strip any bad filepath symbols

    $TaskFileName = $NewTask.Replace(" ", "-")

    $id = "00" + (Get-ChildItem "$PSScriptRoot\Tasks").Count

    $TaskDescription = Read-Host "Description for $NewTask"

    $Requestor = Read-Host "Requestor"
    $Room = Read-Host "Room"
    
    $DueDate = Read-Host "Due Date [Y/N]"
    if ($DueDate -eq 'y') { $DueDate = DatePicker }
    else { $DueDate = $null }

    $Location = Read-Host "Location"

    [PSCustomObject]@{
        id = $id
        'Due Date' = $DueDate
        Name = $NewTask
        Summary = $TaskDescription
        Requestor = $Requestor
        Room = $Room
        Completed = $false
        Location = $Location
        Creator = [System.Environment]::UserName
        Path = "$PSScriptRoot\Tasks\$id-$TaskFileName.json"
    } | ConvertTo-Json | Out-File "$PSScriptRoot\Tasks\$id-$TaskFileName.json"
}

function Get-Tasks() {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false)]
        [switch]
        $All,
        [Parameter(Mandatory=$false)]
        [switch]
        $Oldest,
        [Parameter(Mandatory=$false)]
        [switch]
        $Completed,
        [Parameter(Mandatory=$false)]
        [switch]
        $DueDate
    )

    $Tasks = (Get-ChildItem "$PSScriptRoot\Tasks")
    $TasksArray = @()

    foreach ($Task in $Tasks) {
        $TasksArray += (Get-Content $Task.FullName | ConvertFrom-Json)
    }

    switch ($PSBoundParameters.Keys) {
        'All' { 
            $TasksArray | Select-Object -Property * -ExcludeProperty Path | Sort-Object id -Descending | Format-Table
            $TasksArray | Out-HtmlView -Title "Support Tickets" -DisablePaging
        }
        'Oldest' {
            $TasksArray | Select-Object -Property * -ExcludeProperty Path | Sort-Object id | Format-Table
            $TasksArray | Out-HtmlView -Title "Support Tickets" -DisablePaging
        }
        'Completed' {
            $Counter = 0
            $CompletedArray = @()
            foreach ($CompletedTask in $TasksArray) {
                if ($CompletedTask.Completed -eq $true) {
                    $CompletedArray += $CompletedTask
                    $Counter++
                }
            }
            if ($Counter -eq 0) { Write-Host "There are no completed tasks" -ForegroundColor Yellow; exit }
            $CompletedArray | Select-Object -Property * -ExcludeProperty Path | Sort-Object id -Descending | Format-Table
            $CompletedArray | Out-HtmlView -Title "Completed Tickets" -DisablePaging
        }
        'DueDate' {
            $Counter = 0
            $DueDateArray = @()
            foreach ($DueTask in $TasksArray) {
                if ($null -ne $DueTask.'Due Date') {
                    $DueDateArray += $DueTask
                    $Counter++
                }
            }
            if ($Counter -eq 0) { Write-Host "There are no tasks with due dates" -ForegroundColor Yellow; exit }
            $DueDateArray | Select-Object -Property * -ExcludeProperty Path | Sort-Object {[System.DateTime]::ParseExact($_.'Due Date', "yyyy-MM-dd", $null)} | Format-Table
            $DueDateArray | Out-HtmlView -Title "Upcoming Tickets" -DisablePaging
        }
        Default {}
    }
    
}

function Complete-Task() {
    $Tasks = (Get-ChildItem "$PSScriptRoot\Tasks")
    $TasksArray = @()

    foreach ($Task in $Tasks) {
        $TasksArray += (Get-Content $Task.FullName | ConvertFrom-Json)
    }
    
    $SelectTask = $TasksArray | Out-GridView -PassThru -Verbose
    
    $ConvertCompleted = Get-Content $SelectTask.Path | ConvertFrom-Json
    $ConvertCompleted | ForEach-Object {$_.Completed=$true} | ConvertTo-Json -Depth 32 | Set-Content $SelectTask.Path
}

function Custom-Search() {
    do {
        <# Print the menu; Select the choice #>
        Get-SubMenu
        $Choice = Read-Host "Make a selection"
    
        switch ($Choice) {
            '1' { Get-Tasks -All }
            '2' { Get-Tasks -Oldest }
            '3' { Get-Tasks -Completed }
            '4' { Get-Tasks -DueDate }
            <# Log user quit prompt; Clear the screen; Exit the application #>
            'q' { Clear-Host; exit }
            default { Write-Host "Invalid menu choice" -ForegroundColor Red }  
        }
    } while ($Choice -eq 'q')
}

do {
    <# Print the menu; Select the choice #>
    Get-Menu
    $Choice = Read-Host "Make a selection"

    switch ($Choice) {
        '1' { Create-Task }
        '2' { Complete-Task }
        '3' { Custom-Search }
        <# Log user quit prompt; Clear the screen; Exit the application #>
        'q' { Clear-Host; exit }
        default { Write-Host "Invalid menu choice" -ForegroundColor Red }  
    }
} while ($Choice -eq 'q')