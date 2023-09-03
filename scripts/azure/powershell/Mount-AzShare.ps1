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

# Check if the storage account name is null or empty
if ([string]::IsNullOrEmpty($storageAccountName)) {
    Write-Error -Message "Storage account name cannot be null or empty."
    return
}

$connectTestResult = Test-NetConnection -ComputerName "$storageAccountName.file.core.windows.net" -Port 445
if ($connectTestResult) {
    # Check if the drive $driveLetter already exists
    if (Get-PSDrive -Name $driveLetter -ErrorAction SilentlyContinue) {
        # Remove the drive
        Remove-PSDrive -Name $driveLetter -Force -ErrorAction SilentlyContinue
    }
    # Save the password so the drive will persist on reboot
    cmd.exe /C "cmdkey /add:`"$storageAccountName.file.core.windows.net`" /user:`"$storageAccountName`" /pass:`"$storageAccountKey`""
    # Mount the drive
    New-PSDrive -Name $driveLetter -PSProvider FileSystem -Root "\\$storageAccountName.file.core.windows.net\$fileShareName" -Persist -Scope Global -Credential (New-Object System.Management.Automation.PSCredential ("$storageAccountName", (ConvertTo-SecureString $storageAccountKey -AsPlainText -Force)))
} else {
    Write-Error -Message "Unable to reach the Azure storage account via port 445. Check to make sure your organization or ISP is not blocking port 445, or use Azure P2S VPN, Azure S2S VPN, or Express Route to tunnel SMB traffic over a different port."
}
