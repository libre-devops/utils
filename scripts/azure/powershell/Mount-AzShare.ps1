param (
    [Parameter(Mandatory=$true)]
    [string]$storageAccountName,

    [Parameter(Mandatory=$true)]
    [string]$storageAccountKey,

    [Parameter(Mandatory=$true)]
    [string]$fileShareName,

    [Parameter(Mandatory=$false)]
    [string]$driveLetter = "N"
)

$logFilePath = "C:\mount_script_log_$(Get-Date -Format 'yyyyMMddHHmmss').txt"
Start-Transcript -Path $logFilePath -Append

Write-Output "Script started."

# Check if the storage account name is null or empty
Write-Output "Checking storage account name."
if ([string]::IsNullOrEmpty($storageAccountName)) {
    Write-Error -Message "Storage account name cannot be null or empty."
    Stop-Transcript
    return
}

Write-Output "Testing network connection to $storageAccountName.file.core.windows.net on port 445."
$connectTestResult = Test-NetConnection -ComputerName "$storageAccountName.file.core.windows.net" -Port 445
if ($connectTestResult.TcpTestSucceeded) {
    Write-Output "Connection successful."

    # Check if the drive $driveLetter already exists
    Write-Output "Checking if drive $driveLetter already exists."
    if (Get-PSDrive -Name $driveLetter -ErrorAction SilentlyContinue) {
        Write-Output "Drive $driveLetter exists. Removing..."
        # Remove the drive
        Remove-PSDrive -Name $driveLetter -Force -ErrorAction SilentlyContinue
        Write-Output "Drive $driveLetter removed."
    }

    Write-Output "Saving password for persistence."
    # Save the password so the drive will persist on reboot
    cmd.exe /C "cmdkey /add:`"$storageAccountName.file.core.windows.net`" /user:`"$storageAccountName`" /pass:`"$storageAccountKey`""

    Write-Output "Mounting the drive to $driveLetter."
    # Mount the drive
    New-PSDrive -Name $driveLetter -PSProvider FileSystem -Root "\\$storageAccountName.file.core.windows.net\$fileShareName" -Persist -Scope Global -Credential (New-Object System.Management.Automation.PSCredential ("$storageAccountName", (ConvertTo-SecureString $storageAccountKey -AsPlainText -Force)))

    Write-Output "Drive $driveLetter mounted successfully."
} else {
    Write-Error -Message "Unable to reach the Azure storage account via port 445. Check to make sure your organization or ISP is not blocking port 445, or use Azure P2S VPN, Azure S2S VPN, or Express Route to tunnel SMB traffic over a different port."
}

Stop-Transcript
