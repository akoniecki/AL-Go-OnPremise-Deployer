#     _    _           ____  ___                   "
#    / \  | |         / ___|/ _ \                  "
#   / _ \ | |   _____| |  _| | | |                 "
#  / ___ \| |__|_____| |_| | |_| |                 "
# /_/__ \_\_____|__   \____|\___/       _          "
#  / _ \ _ __ |  _ \ _ __ ___ _ __ ___ (_)___  ___ "
# | | | | '_ \| |_) | '__/ _ \ '_ ` _ \| / __|/ _ \"
# | |_| | | | |  __/| | |  __/ | | | | | \__ \  __/"
#  \___/|_| |_|_|   |_|  \___|_| |_| |_|_|___/\___|"
# |  _ \  ___ _ __ | | ___  _   _  ___ _ __        "
# | | | |/ _ \ '_ \| |/ _ \| | | |/ _ \ '__|       "
# | |_| |  __/ |_) | | (_) | |_| |  __/ |          "
# |____/ \___| .__/|_|\___/ \__, |\___|_|          "
#            |_|            |___/                  "
#
# It's open-source!
# Visit: https://github.com/akoniecki/AL-Go-OnPremise-Deployer

param (
    [Parameter(Mandatory = $true)][string] $PackageData,
    [Parameter(Mandatory = $true)][string] $ServerInstance,
    [Parameter(Mandatory = $true)][string] $Tenant
)

$ErrorActionPreference = "Stop"

Write-Host "*** Package Data File => [$PackageData]"
Write-Host "*** ServerInstance = [$ServerInstance]"
Write-Host "*** Tenant = [$Tenant]"

$PublishScope = "Tenant"
$SkipVerification = $true

Import-Module -Name "ALOps.ExternalDeployer" -Verbose:$false | Out-Null

$ServiceFolder = Get-BCServicePath -ServerInstance $ServerInstance
Write-Host "*** Loading assemblies from: [$ServiceFolder]"

# Load Management module
$MgmtDLL = Get-ChildItem $ServiceFolder -Filter "Microsoft.Dynamics.Nav.Management.dll" -Recurse | Where-Object { -not $_.FullName.Contains("LegacyDlls") } | Select-Object -First 1
if ($MgmtDLL) {
    Import-Module "$($MgmtDLL.FullName)"
}

# Load Apps.Management module
$AppsMgmtDLL = Get-ChildItem $ServiceFolder -Filter "Microsoft.Dynamics.Nav.Apps.Management.dll" -Recurse | Where-Object { -not $_.FullName.Contains("LegacyDlls") } | Select-Object -First 1
if ($AppsMgmtDLL) {
    Import-Module "$($AppsMgmtDLL.FullName)"
}

# Analyze App
$AppInfo = Get-NAVAppInfo -Path $PackageData -Verbose:$false
Write-Host " * App.ID        = $($AppInfo.AppId)"
Write-Host " * App.Name      = $($AppInfo.Name)"
Write-Host " * App.Publisher = $($AppInfo.Publisher)"
Write-Host " * App.Version   = $($AppInfo.Version)"

$PublishedApp = Get-NAVAppInfo -ServerInstance $ServerInstance `
                               -Tenant $Tenant `
                               -TenantSpecificProperties `
                               -Name $AppInfo.Name `
                               -Publisher $AppInfo.Publisher `
                               -Version $AppInfo.Version `
                               -Verbose:$false `
                               -ErrorAction SilentlyContinue

if (($null -eq $PublishedApp) -or (-not $PublishedApp.IsPublished)) {
    Write-Host " => Publishing App '$($AppInfo.Name) v$($AppInfo.Version)'"
    Publish-NAVApp -ServerInstance $ServerInstance `
                   -Path $PackageData `
                   -SkipVerification:$SkipVerification `
                   -PackageType Extension `
                   -Scope $PublishScope `
                   -Tenant $Tenant `
                   -Verbose:$false
} else {
    Write-Host " * App '$($AppInfo.Name) v$($AppInfo.Version)' already published."
}

$Tenants = Get-NAVTenant -ServerInstance $ServerInstance -Tenant $Tenant
foreach ($T in $Tenants) {
    Write-Host "*** Sync Tenant $($T.Id)"

    $PublishedTenantApp = Get-NAVAppInfo -ServerInstance $ServerInstance `
                                         -Name $AppInfo.Name `
                                         -Publisher $AppInfo.Publisher `
                                         -Version $AppInfo.Version `
                                         -TenantSpecificProperties `
                                         -Tenant $T.Id `
                                         -Verbose:$false `
                                         -ErrorAction Stop

    Sync-NAVTenant -ServerInstance $ServerInstance `
                   -Tenant $T.Id `
                   -Mode ForceSync `
                   -Force:$true `
                   -Verbose:$false

    if ($PublishedTenantApp.SyncState -ne [Microsoft.Dynamics.Nav.Types.Apps.NavAppSyncState]::Synced) {
        Write-Host "*** Sync App [$($AppInfo.Name)] on tenant [$($T.Id)]"
        Sync-NAVApp -ServerInstance $ServerInstance `
                    -Name $AppInfo.Name `
                    -Publisher $AppInfo.Publisher `
                    -Version $AppInfo.Version `
                    -Tenant $T.Id `
                    -Mode ForceSync `
                    -Verbose:$false
    }

    if (-not [string]::IsNullOrEmpty($PublishedTenantApp.ExtensionDataVersion) -and $PublishedTenantApp.ExtensionDataVersion -ne $AppInfo.Version) {
        Write-Host "*** Tenant Dataupgrade $($T.Id)"
        Start-NAVAppDataUpgrade -ServerInstance $ServerInstance `
                                -Name $AppInfo.Name `
                                -Publisher $AppInfo.Publisher `
                                -Version $AppInfo.Version `
                                -Tenant $T.Id `
                                -Verbose:$false
    }

    if (-not $PublishedTenantApp.IsInstalled) {
        Write-Host "*** Install App [$($AppInfo.Name)] on tenant [$($T.Id)]"
        Install-NAVApp -ServerInstance $ServerInstance `
                       -Name $AppInfo.Name `
                       -Publisher $AppInfo.Publisher `
                       -Version $AppInfo.Version `
                       -Tenant $T.Id `
                       -Verbose:$false `
                       -ErrorAction SilentlyContinue
    }
}

$OldAppVersions = Get-NAVAppInfo -ServerInstance $ServerInstance `
                                 -Name $AppInfo.Name `
                                 -Publisher $AppInfo.Publisher `
                                 -Tenant $Tenant `
                                 -TenantSpecificProperties `
                                 -Verbose:$false `
                                 -ErrorAction Stop | Where-Object { (-not $_.IsInstalled) -and ($_.Version -ne $AppInfo.Version) } | Sort-Object -Property Version

foreach ($OldAppVersion in $OldAppVersions) {
    Write-Host " * UnPublishing Old App '$($OldAppVersion.Name) v$($OldAppVersion.Version)'."
    Unpublish-NAVApp -ServerInstance $ServerInstance `
                     -Tenant $OldAppVersion.Tenant `
                     -Name $OldAppVersion.Name `
                     -Publisher $OldAppVersion.Publisher `
                     -Version $OldAppVersion.Version `
                     -Verbose:$false
}

Write-Host ""
Write-Host "".PadRight(38,'*')
