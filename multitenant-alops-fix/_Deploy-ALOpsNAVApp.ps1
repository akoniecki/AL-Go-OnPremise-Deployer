Write-Host
Write-Host "     _    _           ____  ___                   "
Write-Host "    / \  | |         / ___|/ _ \                  "
Write-Host "   / _ \ | |   _____| |  _| | | |                 "
Write-Host "  / ___ \| |__|_____| |_| | |_| |                 "
Write-Host " /_/__ \_\_____|__   \____|\___/       _          "
Write-Host "  / _ \ _ __ |  _ \ _ __ ___ _ __ ___ (_)___  ___ "
Write-Host " | | | | '_ \| |_) | '__/ _ \ '_ ` _ \| / __|/ _ \"
Write-Host " | |_| | | | |  __/| | |  __/ | | | | | \__ \  __/"
Write-Host "  \___/|_| |_|_|   |_|  \___|_| |_| |_|_|___/\___|"
Write-Host " |  _ \  ___ _ __ | | ___  _   _  ___ _ __        "
Write-Host " | | | |/ _ \ '_ \| |/ _ \| | | |/ _ \ '__|       "
Write-Host " | |_| |  __/ |_) | | (_) | |_| |  __/ |          "
Write-Host " |____/ \___| .__/|_|\___/ \__, |\___|_|          "
Write-Host "            |_|            |___/                  "
Write-Host
Write-Host "**   It's open source!" 
Write-Host "**   www.github.com/akoniecki/AL-Go-OnPremise-Deployer"
Write-Host "**   Join us on GitHub and contribute!" 
Write-Host "**************************************************************"
Write-Host

$DeployScript = "C:\Program Files\ALOps\ExternalDeployer\AL-Go-OnPremise-Deployer.ps1"

$AllArgs = @(
    "-NoProfile",
    "-ExecutionPolicy", "Bypass",
    "-File", "`"$DeployScript`"",
    "-PackageData", "`"$PackageData`"",
    "-ServerInstance", "`"$ServerInstance`"",
    "-Tenant", "`"$Tenant`""
)

Write-Host "*** Launching isolated deployment for server instance [$ServerInstance], tenant [$Tenant]..."
Start-Process -FilePath "powershell.exe" `
              -ArgumentList $AllArgs `
              -WindowStyle Hidden `
              -Wait
