[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$ScriptPath, # Path to the script you want to execute with the scheduled task

    [string]$TaskName = "MountAzureFileShare", # Default task name

    [string]$TaskDescription = "Script to mount Azure file share",

    [string]$RunAsUser = "NT AUTHORITY\SYSTEM", # Default user

    [Parameter(Mandatory=$false)]
    [string]$UserPassword, # Required if a user other than SYSTEM is specified

    [ValidateSet("AtStartup", "AtLogon", "Daily", "Weekly")]
    [string]$TaskType = "AtStartup", # Default task type

    [string]$ScriptArguments = "" # Additional arguments for the script
)

# Set up transcript for better logging
$transcriptPath = Join-Path -Path $PSScriptRoot -ChildPath "ScheduledTaskCreationLog.txt"
Start-Transcript -Path $transcriptPath -NoClobber:$false

try {
    Write-Host "Preparing to create scheduled task [$TaskName] to run $ScriptPath as $RunAsUser"

    # Ensure the script file exists
    if (-not (Test-Path $ScriptPath)) {
        throw "Script file not found at path: $ScriptPath"
    }

    # Define scheduling type for schtasks command
    switch ($TaskType) {
        "AtStartup" { $schtasksType = "ONSTART" }
        "AtLogon"   { $schtasksType = "ONLOGON" }
        "Daily"     { $schtasksType = "DAILY" }
        "Weekly"   { $schtasksType = "WEEKLY" }
    }

    # Incorporate ScriptArguments into the scheduled task command
    $fullScriptCmd = "powershell.exe -ExecutionPolicy Bypass -NoProfile -File '$ScriptPath' $ScriptArguments"
    $cmd = "schtasks /Create /TN $TaskName /TR ""$fullScriptCmd"" /SC $schtasksType /F /RU $RunAsUser"

    if ($RunAsUser -ne "NT AUTHORITY\SYSTEM") {
        if (-not $UserPassword) {
            throw "UserPassword is required when specifying a user other than SYSTEM."
        }
        $cmd += " /RP $UserPassword"
    }

    Write-Host "Executing command: $cmd"
    Invoke-Expression -Command $cmd

    Write-Output "Scheduled task [$TaskName] created successfully."
}
catch {
    Write-Error $_.Exception.Message
}
finally {
    Stop-Transcript
}
