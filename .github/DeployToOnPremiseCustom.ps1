Param(
    [Parameter(HelpMessage = "AL:Go Custom Deployment Script Parameters", Mandatory = $true)]
    [hashtable] $parameters
)
#
# ######  NOTE  ######
# This file won't be updated/overwritten by AL-Go OnPremise Deployer Update workflow.
# You can safely use it to customize the deployment process, add specific logic and/or for debbuging.
# If you want to rename it, please remember to use correct EnvironmentType in your "DeployTo" settings, matching the filename. (DeployTo<EnvironmentType>.ps1).
#
#


# [ DEBUG ] Display all contents of the $parameters hashtable
Write-Output "[ DEBUG ] Displaying all contents of the AL:Go Custom Deployment `\$parameters` hashtable:"
foreach ($key in $parameters.Keys) {
    $value = $parameters[$key]
    if ($value -is [System.Collections.IEnumerable] -and -not ($value -is [string])) {
        Write-Output "$key :"
        foreach ($item in $value) {
            Write-Output "  - $item"
        }
    } else {
        Write-Output "$key : $value"
    }
}

#
# ######
# Put your customisation here (before deployment)

# ######
#

#
# ===============================================
# Executing AL-Go OnPremise Deployer core script
#
    $ALGoOnPremiseDeployerScript = Join-Path $ENV:GITHUB_WORKSPACE ".github/DeployToOnPremise.ps1"
    if (Test-Path $ALGoOnPremiseDeployerScript) {
        Write-Host "Deployment process handled by AL-Go OnPremise Deployer started."
        . $ALGoOnPremiseDeployerScript -parameters $parameters
        # To disable telemetry: . $ALGoOnPremiseDeployerScript -parameters $parameters -DoNotSendTelemetry
    } else {
        throw "AL-Go OnPremise Deployer files are missing. Run Install/Update workflow and try again"
    }
    Write-Host "Deployment process handled by AL-Go OnPremise Deployer ended."
#
# ===============================================
#

#
# ######
# Put your customisation here (after deployment)

# ######
#