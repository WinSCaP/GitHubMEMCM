param(
    [Parameter(Mandatory=$true)]
    [string[]]$ServerList,

    [Parameter(Mandatory=$true)]
    [char]$ExcludeDriveLetter
)

foreach ($server in $ServerList) {
    try {
        # Initiating a remote session
        $session = New-PSSession -ComputerName $server

        # Fetching drive information
        $drives = Invoke-Command -Session $session -ScriptBlock {
            Get-WmiObject -Class Win32_LogicalDisk | Where-Object { $_.DriveType -eq 3 } # DriveType 3 is for local hard disks
        }

        foreach ($drive in $drives) {
            if ($drive.DeviceID -notlike "$ExcludeDriveLetter*") {
                # Creating the file on the drive
                $filePath = "$($drive.DeviceID)\NO_SMS_ON_DRIVE.SMS"
                Invoke-Command -Session $session -ScriptBlock { param($path) New-Item -Path $path -ItemType File -Force } -ArgumentList $filePath
            }
        }

        # Closing the session
        Remove-PSSession -Session $session
    }
    catch {
        Write-Error "An error occurred on server ${server}: $_"
    }
}
