# --- CONFIGURATION ---

$localInstallerPath = "C:\Users\ext_KVadavi\Downloads\action1_agent(Coats).msi"
$remoteInstallerPath = "C:\Windows\Temp\Action1AgentInstaller.msi"
$remoteServers = @("ADVNHCHV03")
$cred = Get-Credential

# Read the local MSI as bytes
$installerBytes = [System.IO.File]::ReadAllBytes($localInstallerPath)

foreach ($server in $remoteServers) {
    Write-Host "`nProcessing $server..." -ForegroundColor Cyan

    try {
        # Copy installer and install remotely
        Invoke-Command -ComputerName $server -Credential $cred -ScriptBlock {
            param($remoteInstallerPath, $installerBytes)

            Write-Host "Writing MSI to $remoteInstallerPath..." -ForegroundColor Yellow
            [System.IO.File]::WriteAllBytes($remoteInstallerPath, $installerBytes)

            Write-Host "Installing MSI..." -ForegroundColor Yellow
            $msiArgs = "/i `"$remoteInstallerPath`" /quiet /norestart"
            Start-Process -FilePath "msiexec.exe" -ArgumentList $msiArgs -Wait

            Start-Sleep -Seconds 5

            $svc = Get-Service -Name "Action1Agent" -ErrorAction SilentlyContinue
            if ($svc -and $svc.Status -eq 'Running') {
                Write-Output "✅ Installed and running on $env:COMPUTERNAME"
            } else {
                Write-Output "⚠️ Installed but service not running on $env:COMPUTERNAME"
            }

        } -ArgumentList $remoteInstallerPath, $installerBytes
    }
    catch {
        Write-Host "❌ Error on $server : ${_}" -ForegroundColor Red
    }
}