 # Get the directory of the _Deploy-ALOpsNAVApp.ps1 script 
$ScriptDirectory = "C:\Program Files\alops\externaldeployer\bc\psscripts"

# Define the log file name with date and time
$LogFile = Join-Path -Path $ScriptDirectory -ChildPath ("DeployLog_$($PackageData)_$($Tenant)_{0:yyyyMMdd_HHmmss}.log" -f (Get-Date))

# Enable logging
$debugSaveLog = $false

if ($debugSaveLog -eq $true) {
Start-Transcript -Path $LogFile
}

Write-Host "*** Package Data File => [$($PackageData)]"

Write-Host "*** ServerInstance = [$($ServerInstance)]"
Write-Host "*** ContainerId = [$($ContainerId)]"
Write-Host "*** Tenant = [$($Tenant)]"

$PublishScope = "Tenant"
$SkipVerification = $true

Import-Module -Name "ALOps.ExternalDeployer" -Verbose:$false | out-null
$ServiceFolder = Get-BCServicePath -ServerInstance $ServerInstance
Write-Host "*** Loading assemblies from: [$ServiceFolder]"

Write-Host "*** Load module [Microsoft.Dynamics.Nav.Management]"
$FoundDLLPath = $null
$FoundDLLPaths = Get-childItem $ServiceFolder -Filter "Microsoft.Dynamics.Nav.Management.dll" -Recurse | Where-Object { -not $_.FullName.Contains("LegacyDlls") } 
$FoundDLLPath = $FoundDLLPaths | Where-Object { $_.FullName  -ilike "*Management*" }  | Select-Object -First 1
if ($null -eq $FoundDLLPath){
    $FoundDLLPath = $FoundDLLPaths | Select-Object -First 1
}
Import-Module "$($FoundDLLPath.FullName)"   

Write-Host "*** Load module [Microsoft.Dynamics.Nav.Apps.Management]"
$FoundDLLPath = $null
$FoundDLLPaths = Get-childItem $ServiceFolder -Filter "Microsoft.Dynamics.Nav.Apps.Management.dll" -Recurse | Where-Object { -not $_.FullName.Contains("LegacyDlls") } 

$FoundDLLPaths = Get-childItem $ServiceFolder -Filter "Microsoft.Dynamics.Nav.Apps.Management.dll" -Recurse | Where-Object { -not $_.FullName.Contains("LegacyDlls") } 
$FoundDLLPath = $FoundDLLPaths | Where-Object { $_.FullName  -ilike "*Management*" }  | Select-Object -First 1
if ($null -eq $FoundDLLPath){
    $FoundDLLPath = $FoundDLLPaths | Select-Object -First 1
}
if ($null -ne $FoundDLLPath){
    Import-Module "$($FoundDLLPath.FullName)" 
}    


$AppInfo = Get-NAVAppInfo -Path $PackageData -Verbose:$false
Write-Host " * App.ID        = $($AppInfo.AppId)" 
Write-Host " * App.Name      = $($AppInfo.Name)"
Write-Host " * App.Publisher = $($AppInfo.Publisher)"
Write-Host " * App.Version   = $($AppInfo.Version)"

#$PublishedApp = Get-NAVAppInfo -ServerInstance $ServerInstance `
#                               -Name $AppInfo.Name `
#                               -Publisher $AppInfo.Publisher `
#                               -Version $AppInfo.Version `
#                               -Verbose:$false `
#                               -ErrorAction Stop
if ([string]::IsNullOrEmpty($Tenant) -or $Tenant -eq "default") {
$PublishedApp = Get-NAVAppInfo -ServerInstance $ServerInstance `
                               -Name $AppInfo.Name `
                               -Publisher $AppInfo.Publisher `
                               -Version $AppInfo.Version `
                               -Verbose:$false `
                               -ErrorAction Stop
} else {
$PublishedApp = Get-NAVAppInfo -ServerInstance $ServerInstance `
                               -Tenant $Tenant `
                               -TenantSpecificProperties `
                               -Name $AppInfo.Name `
                               -Publisher $AppInfo.Publisher `
                               -Version $AppInfo.Version `
                               -Verbose:$false `
                               -ErrorAction Stop
}

if (($null -eq $PublishedApp) -or (-not $PublishedApp.IsPublished)){
    Write-Host " => Publishing App '$($AppInfo.Name) v$($AppInfo.Version)'"

    if ($PublishScope.ToUpper() -eq "TENANT"){
        Write-Host "*** Publish per Tenant"
        Publish-NAVApp -ServerInstance $ServerInstance `
                       -Path $PackageData `
                       -SkipVerification:$SkipVerification `
                       -PackageType Extension `
                       -Scope $PublishScope `
                       -Tenant $Tenant `
                       -Verbose:$false `
                       -ErrorAction Stop
    } else {
        Write-Host "*** Publish Global"
        Publish-NAVApp -ServerInstance $ServerInstance `
                       -Path $PackageData `
                       -SkipVerification:$SkipVerification `
                       -PackageType Extension `
                       -Scope $PublishScope `
                       -Verbose:$false `
                       -ErrorAction Stop
    }

} else {
    Write-Host " * App '$($AppInfo.Name) v$($AppInfo.Version)' already published."
}     

Write-Host "*** Get Tenants"                    
#$Tenants = Get-NAVTenant -ServerInstance $ServerInstance -Tenant $Tenant
if ([string]::IsNullOrEmpty($Tenant) -or $Tenant -eq "default") {
    $Tenants = Get-NAVTenant -ServerInstance $ServerInstance
} else {
    $Tenants = Get-NAVTenant -ServerInstance $ServerInstance -Tenant $Tenant
}

foreach($Tenant in $Tenants){
    $PublishedTenantApp = Get-NAVAppInfo -ServerInstance $ServerInstance `
                                         -Name $AppInfo.Name `
                                         -Publisher $AppInfo.Publisher `
                                         -Version $AppInfo.Version `
                                         -TenantSpecificProperties `
                                         -Tenant $Tenant.Id `
                                         -Verbose:$false `
                                         -ErrorAction Stop
    
    $Tenant                                         
    $PublishedTenantApp

    Write-Host "*** Sync Tenant $($Tenant.Id)"
    Sync-NAVTenant -ServerInstance $ServerInstance `
                   -Tenant $Tenant.Id `
                   -Mode Sync `
                   -Force:$true `
                   -Verbose:$false `
                   -ErrorAction Stop
                
    Write-Host "*** Sync App [$($AppInfo.Name)] on tenant [$($Tenant.Id)]"
    if ($PublishedTenantApp.SyncState -ne [Microsoft.Dynamics.Nav.Types.Apps.NavAppSyncState]::Synced){        
        Sync-NAVApp -ServerInstance $ServerInstance `
                    -Name $AppInfo.Name `
                    -Publisher $AppInfo.Publisher `
                    -Version $AppInfo.Version `
                    -Tenant $Tenant.Id `
                    -Verbose:$false `
                    -ErrorAction Stop 
    }

    if (-not [string]::IsNullOrEmpty($PublishedTenantApp.ExtensionDataVersion)){
        Write-Host "*** Tenant Dataupgrade $($Tenant.Id)"
        if ($PublishedTenantApp.ExtensionDataVersion -ne $AppInfo.Version) {
            Start-NAVAppDataUpgrade -ServerInstance $ServerInstance `
                                    -Name $AppInfo.Name `
                                    -Publisher $AppInfo.Publisher `
                                    -Version $AppInfo.Version `
                                    -Tenant $Tenant.Id `
                                    -Verbose:$false `
                                    -ErrorAction Stop
        }
    } 
    
    if (-not $PublishedTenantApp.IsInstalled){
        Write-Host "*** Install App [$($AppInfo.Name)] on tenant [$($Tenant.Id)]"
        Install-NAVApp -ServerInstance $ServerInstance `
                       -Name $AppInfo.Name `
                       -Publisher $AppInfo.Publisher `
                       -Version $AppInfo.Version `
                       -Tenant $Tenant.Id `
                       -Verbose:$false `
                       -ErrorAction SilentlyContinue  
    }

}

#$OldAppVersions = Get-NAVAppInfo -ServerInstance $ServerInstance `
#                                 -Name $AppInfo.Name `
#                                 -Publisher $AppInfo.Publisher `
#                                 -Verbose:$false `
#                                 -ErrorAction Stop | Where-Object { (-not $_.IsInstalled) -and ($_.Version -ne $AppInfo.Version) } | Sort-Object -Property Version
if ([string]::IsNullOrEmpty($Tenant) -or $Tenant -eq "default") {
$OldAppVersions = Get-NAVAppInfo -ServerInstance $ServerInstance `
                                 -Name $AppInfo.Name `
                                 -Publisher $AppInfo.Publisher `
                                 -Verbose:$false `
                                 -ErrorAction Stop | Where-Object { (-not $_.IsInstalled) -and ($_.Version -ne $AppInfo.Version) } | Sort-Object -Property Version
} else {
$OldAppVersions = Get-NAVAppInfo -ServerInstance $ServerInstance `
                                 -Name $AppInfo.Name `
                                 -Publisher $AppInfo.Publisher `
                                 -Tenant $AppInfo.Tenant `
                                 -Verbose:$false `
                                 -ErrorAction Stop | Where-Object { (-not $_.IsInstalled) -and ($_.Version -ne $AppInfo.Version) } | Sort-Object -Property Version
}
foreach ($OldAppVersion in $OldAppVersions){
    Write-Host " * UnPublishing Old App '$($OldAppVersion.Name) v$($OldAppVersion.Version)'."
    #Unpublish-NAVApp -ServerInstance $ServerInstance `
    #                 -Name $OldAppVersion.Name `
    #                 -Publisher $OldAppVersion.Publisher `
    #                 -Version $OldAppVersion.Version `
    #                 -Verbose:$false `
    #                 -ErrorAction Stop
    if ([string]::IsNullOrEmpty($Tenant) -or $Tenant -eq "default") {
        Unpublish-NAVApp -ServerInstance $ServerInstance `
                         -Name $OldAppVersion.Name `
                         -Publisher $OldAppVersion.Publisher `
                         -Version $OldAppVersion.Version `
                         -Verbose:$false `
                         -ErrorAction Stop
     } else {
        Unpublish-NAVApp -ServerInstance $ServerInstance `
                         -Tenant $OldAppVersion.Tenant `
                         -Name $OldAppVersion.Name `
                         -Publisher $OldAppVersion.Publisher `
                         -Version $OldAppVersion.Version `
                         -Verbose:$false `
                         -ErrorAction Stop    
     }

}

Write-Host ""
Write-Host "".PadRight(38,'*')
Write-Host ""

if ($debugSaveLog -eq $true) {
# Stop logging
Stop-Transcript 
}