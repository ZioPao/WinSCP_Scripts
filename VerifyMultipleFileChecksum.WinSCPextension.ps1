# @name         Verify Multiple Checksum
# @command      powershell.exe -ExecutionPolicy Bypass -File "%EXTENSION_PATH%" ^
#                   -sessionUrl "!E" -localPath "!^!" -remotePath "!/!" -pause ^
#                   -sessionLogPath "%SessionLogPath%"
# @description  Compares checksums of the selected local and remote file
# @flag         RemoteFiles
# @version      6
# @homepage     https://winscp.net/eng/docs/library_example_verify_file_checksum
# @require      WinSCP 5.16
# @option       SessionLogPath -config sessionlogfile
# @optionspage  https://winscp.net/eng/docs/library_example_verify_file_checksum#options
 
param (
    # Use Generate Session URL function to obtain a value for -sessionUrl parameter.
    $sessionUrl = "sftp://user:mypassword;fingerprint=ssh-rsa-xxxxxxxxxxx...@example.com/",
    [Parameter(Mandatory = $True)]
    $localPath,
    [Parameter(Mandatory = $True)]
    $remotePath,
    $sessionLogPath = $Null,
    [Switch]
    $pause
)
 
try
{
    # E:\Games\Call of Duty Modern Warfare 2 Campaign Remastered\Data\data\000000000e.idx
    # /run/media/something/test.idx
    Write-Host $localPath

 
    # Calculate local file checksum
    $sha1 = [System.Security.Cryptography.SHA1]::Create()
    $localStream = [System.IO.File]::OpenRead($localPath)
    $localChecksum = [System.BitConverter]::ToString($sha1.ComputeHash($localStream))
 
    Write-Host $localChecksum
    
    # Load WinSCP .NET assembly
    $assemblyPath = if ($env:WINSCP_PATH) { $env:WINSCP_PATH } else { $PSScriptRoot }
    Add-Type -Path (Join-Path $assemblyPath "WinSCPnet.dll")
 
    # Setup session options
    $sessionOptions = New-Object WinSCP.SessionOptions
    $sessionOptions.ParseUrl($sessionUrl)
 
    $session = New-Object WinSCP.Session
 
    try
    {
        $session.SessionLogPath = $sessionLogPath

        # Connect
        $session.Open($sessionOptions)

        $localFileName = Split-Path -Path $localPath -Leaf
        $lastSlashIndex = $remotePath.LastIndexOf('/')
        $remotePath = $remotePath.Substring(0, $lastSlashIndex)
    
        # let's assume that the remote is a linux machine
        $remotePath = "$remotePath/$localFileName"
        Write-Host $remotePath
 
        # Calculate remote file checksum
        $remoteChecksumBytes = $session.CalculateFileChecksum("sha-1", $remotePath)
        $remoteChecksum = [System.BitConverter]::ToString($remoteChecksumBytes)
        Write-Host $remoteChecksum
    }
    finally
    {
        # Disconnect, clean up
        $session.Dispose()
    }
 
    # Compare cheksums
    if ($localChecksum -eq $remoteChecksum)
    {
        Write-Host "Match"
        $result = 0
    }
    else
    {
        Write-Host "Does NOT match"
        $result = 1
    }
}
catch
{
    Write-Host "Error: $($_.Exception.Message)"
    $result = 1
}
 
if ($result -eq 1)
{
    Write-Host "Press any key to exit..."
    [System.Console]::ReadKey() | Out-Null
}
 
exit $result
