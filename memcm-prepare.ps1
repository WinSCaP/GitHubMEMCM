# Import the JSON config file
$global:config = Get-Content -Path '.\config.json' | ConvertFrom-Json

# This code block is attempting to create a temporary directory specified in the `config.json` file.
# It first checks if the directory already exists using the `Test-Path` cmdlet. If the directory does
# not exist, it creates it using the `New-Item` cmdlet with the `-ItemType Directory` parameter. If
# the directory creation fails, it catches the error using a `try-catch` block and writes an error
# message to the console. If an error occurs, the script execution is stopped using the `exit` command
# with a status code of 1.
try {
    # Check if the directory already exists
    if (-not (Test-Path -Path $$config.installworkdir)) {
        # Create the directory
        New-Item -ItemType Directory -Path $$config.installworkdir -ErrorAction Stop
        Write-Host "Created temporary directory at $$config.installworkdir"
    }
    else {
        Write-Host "Temporary directory already exists at $$config.installworkdir"
    }
}
catch {
    Write-Error "Failed to create temporary directory at $$config.installworkdir"
    Write-Error $_.Exception.Message
    # Stop the script execution on failure
    exit 1
}


# This code block is iterating through a list of servers specified in the `config.json` file and
# installing .NET 3.5 on each server. It uses the `Invoke-Command` cmdlet to run a script block on
# each server, which downloads `wget.exe`, downloads the Windows Server ISO, mounts the ISO, installs
# .NET 3.5 using the `Add-WindowsFeature` cmdlet, dismounts the ISO, and cleans up the temporary
# files. The `.isoUrl` and `.wgetUrl` variables are passed as arguments to the script
# block.
foreach ($server in $config.servers) {
    Write-Host "Installing .NET 3.5 on $server..."

    Invoke-Command -ComputerName $server -ScriptBlock {
        param($isoUrl, $wgetUrl)

        # Set the temp directory
        $tempDir = $global:config.installworkdir

        # Download wget.exe
        Write-Host "Downloading wget.exe..."
        $webClient = New-Object System.Net.WebClient
        $webClient.DownloadFile($wgetUrl, "$tempDir\wget.exe")

        # Download the ISO
        Write-Host "Downloading Windows Server ISO..."
        & "$tempDir\wget.exe" $isoUrl -OutFile "$tempDir\windows_server_2022.iso"

        # Mount the ISO
        $isoDrive = (Mount-DiskImage -ImagePath "$tempDir\windows_server_2022.iso" -PassThru | Get-Volume).DriveLetter

        # Path to the SxS folder
        $sxsPath = $isoDrive + ":\sources\sxs"

        # Import the necessary module
        Import-Module ServerManager

        # Install .NET 3.5
        Add-WindowsFeature -Name NET-Framework-Core -Source $sxsPath

        # Dismount the ISO
        Dismount-DiskImage -ImagePath "$tempDir\windows_server_2022.iso"

        # Clean up
        Remove-Item -Path "$tempDir\windows_server_2022.iso"
        Remove-Item -Path "$tempDir\wget.exe"
    } -ArgumentList $config.isoUrl, $config.wgetUrl
}
