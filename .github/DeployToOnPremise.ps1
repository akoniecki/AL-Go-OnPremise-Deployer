Param(
    [Parameter(Mandatory = $true)]
    [hashtable] $parameters,
    [Parameter(HelpMessage = "We gather anonymized usage telemetry data to make the AL-Go OnPremise Deployer tool even better.", Mandatory = $false)]
    [switch]$DoNotSendTelemetry)

Write-Host
Write-Host "===============================================" -ForegroundColor Cyan
Write-Host "       Welcome to AL-Go OnPremise Deployer      " -ForegroundColor Yellow
Write-Host "===============================================" -ForegroundColor Cyan
Write-Host
Write-Host "It's open source! Join us on GitHub:" -ForegroundColor Green
Write-Host "www.github.com/akoniecki/AL-Go-OnPremise-Deployer" -ForegroundColor Blue
Write-Host
Write-Host "Give the GitHub project a star, share, and contribute!" -ForegroundColor Magenta
Write-Host

function Send-TelemetryData {
    param (
        [string]$status
    )
    $webhookUrl = "" 
    $hash = [System.Security.Cryptography.SHA256]::Create()
    $githubUserHash = [BitConverter]::ToString($hash.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($env:GITHUB_ACTOR))) -replace '-', ''
    $repositoryHash = [BitConverter]::ToString($hash.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($env:GITHUB_REPOSITORY))) -replace '-', ''
    $payload = @{ githubUser = $githubUserHash; repository = $repositoryHash; status = $status } | ConvertTo-Json
    try { 
        #Invoke-RestMethod -Uri $webhookUrl -Method Post -ContentType 'application/json' -Body $payload 
        Write-Host "[ DEBUG ] Telemetry payload sent: $payload"
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

# Find the latest versions of required heplers
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
try {
    $authContextParams = $parameters.AuthContext | ConvertFrom-Json | ConvertTo-HashTable 
    $authContext = New-BcAuthContext @authContextParams
    if ($null -eq $authContext) {
        throw "Authentication failed"
    }
    Write-Host "Authentication successful, authContext created."
} catch {
    throw "Authentication failed. $([environment]::Newline) $($_.exception.message)"
}

# Preparing automation API connection
Write-Host "Preparing automation API connection..."
if (-not ($authContextParams.ContainsKey('apiBaseUrl') -and $authContextParams.apiBaseUrl)) {
    throw "AuthContext parameter ""apiBaseUrl"" does not exist or is empty."
}
$environmentUrl = "$($authContextParams.apiBaseUrl.TrimEnd('/'))/$($parameters.EnvironmentName)"
Add-Content -Encoding UTF8 -Path $env:GITHUB_OUTPUT -Value "environmentUrl=$environmentUrl"
Write-Host "EnvironmentUrl: $environmentUrl"

$response = Invoke-RestMethod -UseBasicParsing -Method Get -Uri "$environmentUrl/deployment/url"
if ($response.Status -eq "DoesNotExist") {
    OutputError -message "Environment with name $($parameters.EnvironmentName) does not exist in the current authorization context."
    exit
}
if ($response.Status -ne "Ready") {
    OutputError -message "Environment with name $($parameters.EnvironmentName) is not ready (Status is $($response.Status))."
    exit
}

try {
    $deployParameters = @{
        "bcAuthContext" = $authContext
        "environment" = $parameters.EnvironmentName
        "appFiles" = $parameters.Apps
        "schemaSyncMode" = "Add"
        "companyName" = $parameters.companyName
    }
    $schemaSyncMode = $deployParameters.schemaSyncMode
    $companyName = $deployParameters.companyName

    Write-Host "Publishing apps to environment using automation API"

    function GetAuthHeaders {
        $authContext = Renew-BcAuthContext -bcAuthContext $authContext
        return @{ "Authorization" = "Bearer $($authContext.AccessToken)" } 
    }

    $appFolder = Join-Path ([System.IO.Path]::GetTempPath()) ([guid]::NewGuid().ToString())
    $appFiles = CopyAppFilesToFolder -appFiles $deployParameters.appFiles -folder $appFolder

    $automationApiUrl = "$($authContextParams.apiBaseUrl.TrimEnd('/'))/$($parameters.EnvironmentName)/api/microsoft/automation/v2.0"

    Write-Host "$automationApiUrl/companies"
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $companies = Invoke-RestMethod -Headers (GetAuthHeaders) -Method Get -Uri "$automationApiUrl/companies" -UseBasicParsing
    $company = $companies.value | Where-Object { ($companyName -eq "") -or ($_.name -eq $companyName) } | Select-Object -First 1
    if (!($company)) {
        throw "No company $companyName"
    }
    $companyId = $company.id
    if ($companyName -eq "") {
        $companyName = $company.name
    }
    Write-Host "Company '$companyName' has id $companyId"
    
    Write-Host "$automationApiUrl/companies($companyId)/extensions"
    $getExtensions = Invoke-WebRequest -Headers (GetAuthHeaders) -Method Get -Uri "$automationApiUrl/companies($companyId)/extensions" -UseBasicParsing
    $extensions = (ConvertFrom-Json $getExtensions.Content).value | Sort-Object -Property DisplayName
    
    Write-Host "Extensions before:"
    $extensions | ForEach-Object { Write-Host " - $($_.DisplayName), Version $($_.versionMajor).$($_.versionMinor).$($_.versionBuild).$($_.versionRevision), Installed=$($_.isInstalled)" }
    Write-Host

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
            $extensionUpload = (Invoke-RestMethod -Method Get -Uri "$automationApiUrl/companies($companyId)/extensionUpload" -Headers (GetAuthHeaders)).value
            Write-Host "."
            if ($extensionUpload -and $extensionUpload.systemId) {
                $extensionUpload = Invoke-RestMethod `
                    -Method Patch `
                    -Uri "$automationApiUrl/companies($companyId)/extensionUpload($($extensionUpload.systemId))" `
                    -Headers ((GetAuthHeaders) + $ifMatchHeader + $jsonHeader) `
                    -Body ($body | ConvertTo-Json -Compress)
            }
            else {
                $ExtensionUpload = Invoke-RestMethod `
                    -Method Post `
                    -Uri "$automationApiUrl/companies($companyId)/extensionUpload" `
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
            Write-Host "CustomUri: $customUri"

            Invoke-RestMethod `
                -Method Patch `
                -Uri $customUri `
                -Headers ((GetAuthHeaders) + $ifMatchHeader + $streamHeader) `
                -Body $fileBody | Out-Null
            Write-Host "."    
            Invoke-RestMethod `
                -Method Post `
                -Uri "$automationApiUrl/companies($companyId)/extensionUpload($($extensionUpload.systemId))/Microsoft.NAV.upload" `
                -Headers ((GetAuthHeaders) + $ifMatchHeader) | Out-Null
            Write-Host "."    
            $completed = $false
            $errCount = 0
            $sleepSeconds = 30
            while (!$completed)
            {
                Start-Sleep -Seconds $sleepSeconds
                try {
                    $extensionDeploymentStatusResponse = Invoke-WebRequest -Headers (GetAuthHeaders) -Method Get -Uri "$automationApiUrl/companies($companyId)/extensionDeploymentStatus" -UseBasicParsing
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
    $getExtensions = Invoke-WebRequest -Headers (GetAuthHeaders) -Method Get -Uri "$automationApiUrl/companies($companyId)/extensions" -UseBasicParsing
    $extensions = (ConvertFrom-Json $getExtensions.Content).value | Sort-Object -Property DisplayName
    Write-Host
    Write-Host "Extensions after:"
    $extensions | ForEach-Object { Write-Host " - $($_.DisplayName), Version $($_.versionMajor).$($_.versionMinor).$($_.versionBuild).$($_.versionRevision), Installed=$($_.isInstalled)" }

    if (Test-Path $appFolder) {
        Remove-Item $appFolder -Recurse -Force -ErrorAction SilentlyContinue
    }
}