Param(
    [Parameter(Mandatory = $true)]
    [hashtable] $parameters,
    [Parameter(HelpMessage = "We gather anonymized usage telemetry data to make the AL-Go OnPremise Deployer tool even better.", Mandatory = $false)]
    [switch]$DoNotSendTelemetry
)

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

function Send-TelemetryData {
    param (
        [string]$status
    )
    $webhookUrl = "https://algoonpremisedeployer.azurewebsites.net/api/Usage" 
    $hash = [System.Security.Cryptography.SHA256]::Create()
    $githubUserHash = [BitConverter]::ToString($hash.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($env:GITHUB_ACTOR))) -replace '-', ''
    $repositoryHash = [BitConverter]::ToString($hash.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($env:GITHUB_REPOSITORY))) -replace '-', ''
    $payload = @{ GithubUser = $githubUserHash; Repository = $repositoryHash; Status = $status } | ConvertTo-Json
    try { 
        Invoke-RestMethod -Uri $webhookUrl -Method Post -ContentType 'application/json' -Body $payload
    } catch { 
        Write-Host "Failed to send usage statistics: $($_.Exception.Message)" 
    }
}

# Send usage statistics (data anonymized)
if (-not $DoNotSendTelemetry) {
    Send-TelemetryData -status "started"
}
    
# AL:Go and BCContainerHelper helper libraries import
Write-Host "Importing AL:Go and BCContainerHelper helper libraries..."
$helperBasePath = "..\..\_actions\microsoft\AL-Go-Actions\"
$bcContainerHelperBasePath = "C:\ProgramData\BcContainerHelper\"

# Find the latest versions of required helpers
$alGoActionsPath = Get-ChildItem -Path $helperBasePath -Directory | 
    Sort-Object Name -Descending | 
    Select-Object -First 1
if ($null -eq $alGoActionsPath) {
    throw "AL-Go-Actions directory not found."
}
Write-Host "AL-Go Actions path: $($alGoActionsPath.Fullname)"

$versionRegex = '^\d+\.\d+\.\d+$'
$bcContainerHelperPath = Get-ChildItem -Path $bcContainerHelperBasePath -Directory | 
    Where-Object { $_.Name -match $versionRegex } |
    Sort-Object Name -Descending | 
    Select-Object -First 1
if ($null -eq $bcContainerHelperPath) {
    throw "BcContainerHelper directory not found."
}
Write-Host "BcContainerHelper path: $($bcContainerHelperPath.FullName)"

# Importing helpers
$helperPath = Join-Path -Path $alGoActionsPath.FullName -ChildPath "AL-Go-Helper.ps1"
. $helperPath
DownloadAndImportBcContainerHelper
$bcHelperFunctionsPath = Join-Path -Path $bcContainerHelperPath.FullName -ChildPath "BcContainerHelper\HelperFunctions.ps1"
. $bcHelperFunctionsPath

# Authentication: authContext
Write-Host "Authenticating..."
$authContext = $null
$basicAuth = $null
try {
    $authContextParams = $parameters.AuthContext | ConvertFrom-Json | ConvertTo-HashTable
    if ($authContextParams.ContainsKey('ClientSecret') -and $authContextParams.ClientSecret) {
        Write-Host "Entra ID authentication"
        $authContext = New-BcAuthContext @authContextParams
        if ($null -eq $authContext) {
            throw "AuthContext could not be created."
        }
        Write-Host "Authentication successful, authContext created."
    } elseif ($authContextParams.ContainsKey('Username') -and $authContextParams.ContainsKey('Password')) {
        Write-Host "Basic authentication"
        $basicAuth = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes("$($authContextParams.Username):$($authContextParams.Password)"))
    } else {
        throw "No valid authentication method found in AuthContext parameters."
    }
} catch {
    throw "Authentication failed. $([environment]::Newline) $($_.exception.message)"
}

# Preparing Automation API url
Write-Host "Preparing URL for Automation API endpoint..."
if (-not ($authContextParams.ContainsKey('apiBaseUrl') -and $authContextParams.apiBaseUrl)) {
    throw "AuthContext parameter ""apiBaseUrl"" does not exist or is empty."
}
$environmentUrl = "$($authContextParams.apiBaseUrl.TrimEnd('/'))/$($parameters.EnvironmentName)"
Add-Content -Encoding UTF8 -Path $env:GITHUB_OUTPUT -Value "environmentUrl=$environmentUrl"
Write-Host "Automation API endpoint: $environmentUrl"

# Multitenant deployment
if ($authContextParams.ContainsKey('Tenant') -and $authContextParams.Tenant) {
    $tenant = $authContextParams.Tenant
    $tenantUrl = "?tenant=$tenant"
    Write-Host "Multitenant environment. Tenant in use: $tenant"
} else {
    $tenantUrl = ""
    Write-Host "Single-tenant environment. AuthContext parameter ""Tenant"" not found. "
}

try {
    $deployParameters = @{
        "bcAuthContext" = $authContext
        "environment" = $parameters.EnvironmentName
        "appFiles" = $parameters.Apps
        "schemaSyncMode" = "Add"
    }
    $schemaSyncMode = $deployParameters.schemaSyncMode
    $companyName = if ($parameters.PSObject.Properties["companyName"]) { $parameters.companyName } else { "" }

    Write-Host "Publishing apps to environment using automation API"

    function GetAuthHeaders {
        if ($null -ne $authContext) {
            $authContext = Renew-BcAuthContext -bcAuthContext $authContext
            return @{ "Authorization" = "Bearer $($authContext.AccessToken)" } 
        } elseif ($null -ne $basicAuth) {
            return @{ "Authorization" = "Basic $($basicAuth)" } 
        } else {
            throw "No valid authentication method available."
        }
    }

    $appFolder = Join-Path ([System.IO.Path]::GetTempPath()) ([guid]::NewGuid().ToString())
    $appFiles = CopyAppFilesToFolder -appFiles $deployParameters.appFiles -folder $appFolder

    $automationApiUrl = "$($authContextParams.apiBaseUrl.TrimEnd('/'))/$($parameters.EnvironmentName)/api/microsoft/automation/v2.0"

    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $companies = Invoke-RestMethod -Headers (GetAuthHeaders) -Method Get -Uri "$automationApiUrl/companies$tenantUrl" -UseBasicParsing
    $company = $companies.value | Where-Object { ($companyName -eq "") -or ($_.name -eq $companyName) } | Select-Object -First 1
    if (!($company)) {
        throw "No company $companyName"
    }
    $companyId = $company.id
    if ($companyName -eq "") {
        $companyName = $company.name
    }
    Write-Host "Company '$companyName' has id $companyId"
    
    $getExtensions = Invoke-WebRequest -Headers (GetAuthHeaders) -Method Get -Uri "$automationApiUrl/companies($companyId)/extensions$tenantUrl" -UseBasicParsing
    $extensions = (ConvertFrom-Json $getExtensions.Content).value | Sort-Object -Property DisplayName

    $body = @{"schedule" = "Current Version"}
    $appDep = $extensions | Where-Object { $_.DisplayName -eq 'Application' }
    $appDepVer = [System.Version]"$($appDep.versionMajor).$($appDep.versionMinor).$($appDep.versionBuild).$($appDep.versionRevision)"
    if ($appDepVer -ge [System.Version]"21.2.0.0") {
        if ($schemaSyncMode -eq 'Force') {
            $body."SchemaSyncMode" = "Force Sync"
        }
        else {
            $body."SchemaSyncMode" = "Add"
        }
    }
    else {
        if ($schemaSyncMode -eq 'Force') {
            throw 'SchemaSyncMode Force is not supported before version 21.2'
        }
    }

    $ifMatchHeader = @{ "If-Match" = '*'}
    $jsonHeader = @{ "Content-Type" = 'application/json'}
    $streamHeader = @{ "Content-Type" = 'application/octet-stream'}

    Sort-AppFilesByDependencies -appFiles $appFiles -excludeRuntimePackages | ForEach-Object {
        Write-Host -NoNewline "$([System.IO.Path]::GetFileName($_)) - "
        $appJson = Get-AppJsonFromAppFile -appFile $_
        
        $existingApp = $extensions | Where-Object { $_.id -eq $appJson.id -and $_.isInstalled }
        if ($existingApp) {
            if ($existingApp.isInstalled) {
                $existingVersion = [System.Version]"$($existingApp.versionMajor).$($existingApp.versionMinor).$($existingApp.versionBuild).$($existingApp.versionRevision)"
                if ($existingVersion -ge $appJson.version) {
                    Write-Host "already installed"
                }
                else {
                    Write-Host "upgrading"
                    $existingApp = $null
                }
            }
            else {
                Write-Host "installing"
                $existingApp = $null
            }
        }
        else {
            Write-Host "publishing and installing"
        }
        if (!$existingApp) {
            $extensionUpload = (Invoke-RestMethod -Method Get -Uri "$automationApiUrl/companies($companyId)/extensionUpload$tenantUrl" -Headers (GetAuthHeaders)).value
            Write-Host "."
            if ($extensionUpload -and $extensionUpload.systemId) {
                $extensionUpload = Invoke-RestMethod `
                    -Method Patch `
                    -Uri "$automationApiUrl/companies($companyId)/extensionUpload($($extensionUpload.systemId))$tenantUrl" `
                    -Headers ((GetAuthHeaders) + $ifMatchHeader + $jsonHeader) `
                    -Body ($body | ConvertTo-Json -Compress)
            }
            else {
                $ExtensionUpload = Invoke-RestMethod `
                    -Method Post `
                    -Uri "$automationApiUrl/companies($companyId)/extensionUpload$tenantUrl" `
                    -Headers ((GetAuthHeaders) + $jsonHeader) `
                    -Body ($body | ConvertTo-Json -Compress)
            }
            Write-Host "."
            if ($null -eq $extensionUpload.systemId) {
                throw "Unable to upload extension"
            }
            $fileBody = [System.IO.File]::ReadAllBytes($_)

            # Custom Uri support added for OnPremise deployment
            $customUri = $extensionUpload.'extensionContent@odata.mediaEditLink'
            $customUriStartIndex = $customUri.IndexOf("/companies")
            $customUri = $customUri.Substring($customUriStartIndex)
            $customUri = $automationApiUrl + $customUri

            Invoke-RestMethod `
                -Method Patch `
                -Uri $customUri$tenantUrl `
                -Headers ((GetAuthHeaders) + $ifMatchHeader + $streamHeader) `
                -Body $fileBody | Out-Null
            Write-Host "."    
            Invoke-RestMethod `
                -Method Post `
                -Uri "$automationApiUrl/companies($companyId)/extensionUpload($($extensionUpload.systemId))/Microsoft.NAV.upload$tenantUrl" `
                -Headers ((GetAuthHeaders) + $ifMatchHeader) | Out-Null
            Write-Host "."    
            $completed = $false
            $errCount = 0
            $sleepSeconds = 30
            while (!$completed)
            {
                Start-Sleep -Seconds $sleepSeconds
                try {
                    $extensionDeploymentStatusResponse = Invoke-WebRequest -Headers (GetAuthHeaders) -Method Get -Uri "$automationApiUrl/companies($companyId)/extensionDeploymentStatus$tenantUrl" -UseBasicParsing
                    $extensionDeploymentStatuses = (ConvertFrom-Json $extensionDeploymentStatusResponse.Content).value

                    $completed = $true
                    $extensionDeploymentStatuses | Where-Object { $_.publisher -eq $appJson.publisher -and $_.name -eq $appJson.name -and $_.appVersion -eq $appJson.version } | % {
                        if ($_.status -eq "InProgress") {
                            Write-Host "."
                            $completed = $false
                        }
                        elseif ($_.Status -eq "Unknown") {
                            throw "Unknown Error"
                        }
                        elseif ($_.Status -ne "Completed") {
                            $errCount = 5
                            throw $_.status
                        }
                    }
                    $errCount = 0
                    $sleepSeconds = 5
                }
                catch {
                    if ($errCount++ -gt 4) {
                        Write-Host $_.Exception.Message
                        throw "Unable to publish app. Please open the Extension Deployment Status Details page in Business Central to see the detailed error message."
                    }
                    $sleepSeconds += $sleepSeconds
                    $completed = $false
                }
            }
            if ($completed) {
                Write-Host "completed"
            }
        }
    }
    if (-not $DoNotSendTelemetry) {
        Send-TelemetryData -status "completed"
    }
}
catch {
    OutputError -message "Deploying to $($deploymentSettings.EnvironmentName) failed.$([environment]::Newline) $($_.Exception.Message)"
    if (-not $DoNotSendTelemetry) {
        Send-TelemetryData -status "failed"
    }
    exit
}
finally {
    if (Test-Path $appFolder) {
        Remove-Item $appFolder -Recurse -Force -ErrorAction SilentlyContinue
    }
}
