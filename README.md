# AL-Go OnPremise Deployer 🚀

## Overview
**AL-Go OnPremise Deployer** extends [AL-Go for GitHub](https://github.com/microsoft/AL-Go) to enable deployment to Business Central’s on-premise environments, previously limited to SaaS.

![Integration with AL-Go](https://i.pinimg.com/originals/4f/7e/ab/4f7eab8b98913e658391c54b57980e68.gif)

[![CI/CD Status](https://img.shields.io/github/actions/workflow/status/akoniecki/AL-Go-OnPremise-Deployer/CICD.yml)](https://github.com/akoniecki/AL-Go-OnPremise-Deployer/actions)
[![License](https://img.shields.io/github/license/akoniecki/AL-Go-OnPremise-Deployer)](LICENSE)
[![Contributor Covenant](https://img.shields.io/badge/Contributor%20Covenant-2.1-4baaaa.svg)](CODE_OF_CONDUCT.md)

## Table of Contents
- [Features](#-features)
- [Installation Methods](#-installation-methods)
- [Core Files](#-core-files)
- [Additional Files](#-additional-files)
- [Usage](#-usage)
- [Contributing](#-contributing)
- [License](#-license)
- [Feedback & Issues](#-feedback--issues)
- [Acknowledgements](#-acknowledgements)
- [Contact](#-contact)

## 🚀 Features
- **On-Premise Deployment:** Easily deploy Business Central's AL extensions to on-premise environments.
- **AL-Go for GitHub Integration:** Seamless integration with [AL-Go for GitHub](https://github.com/microsoft/AL-Go) using the built-in custom deployment scripts feature.
- **Automation API:** No GitHub Agent installation required. The modern deployment process utilizes Business Central's Automation API.
- **Easy Installation:** Simply add the [OnPremiseDeployer.yaml](https://github.com/akoniecki/AL-Go-OnPremise-Deployer/blob/main/.github/workflows/OnPremiseDeployer.yaml) workflow file to your AL-Go repository and run it.
- **Automatic Updates:** New "UpdateOnPremiseDeployerSchedule" setting in `AL-Go-Settings.json` to enable an automatic update schedule.

## 📥 Installation
1. **Using the Workflow File:**
    - Download and place the [OnPremiseDeployer.yaml](https://github.com/akoniecki/AL-Go-OnPremise-Deployer/blob/main/.github/workflows/OnPremiseDeployer.yaml) file in the `.github/workflows` path of your AL-Go repository.
    - Ensure you have a valid `ghWorkflowToken` secret available in your AL-Go repository. See [AL-Go docs](https://github.com/microsoft/AL-Go/blob/main/Scenarios/UpdateAlGoSystemFiles.md) for more information.
    - Run the "Install or Update AL-Go OnPremise Deployer" workflow in GitHub Actions.

2. **Using the Repository Template:**
    - Click "Use this template" on the repository page and follow the wizard.

3. **Offline Installation:**
    - Just copy the AL-Go OnPremise **core files** to your AL-Go repository. Additionally, you can include **additional files**, such as setting template for a quick start or customizable deployment script for more advanced cases.

## 🛠️ Core Files
- **[`.github/DeployToOnPremise.ps1`](https://github.com/akoniecki/AL-Go-OnPremise-Deployer/blob/main/.github/DeployToOnPremise.ps1)**: Core script for handling on-premise deployments.
- **[`.github/workflows/OnPremiseDeployer.yaml`](https://github.com/akoniecki/AL-Go-OnPremise-Deployer/blob/main/.github/workflows/OnPremiseDeployer.yaml)**: GitHub Action for installing/updating AL-Go OnPremise Deployer.

## 🧰 Additional Files
- **[`.github/DeployToOnPremiseCustom.ps1`](https://github.com/akoniecki/AL-Go-OnPremise-Deployer/blob/main/.github/DeployToOnPremiseCustom.ps1)**: Customizable on-premise deployment script.
- **[`.github/AL-Go-Settings.ps1`](https://github.com/akoniecki/AL-Go-OnPremise-Deployer/blob/main/.github/AL-Go-Settings.ps1)**: Template configuration file.

## 📈 Usage    
1. **Automatic Updates:**
    - Configure `UpdateOnPremiseDeployerSchedule` in `AL-Go-Settings.ps1`:
        ```json
        {
            "UpdateOnPremiseDeployerSchedule": "0 19 * * 2"
        }
        ```
    - Run the "Install or Update AL-Go OnPremise Deployer" workflow to apply scheduler changes.

2. **Configure Environments:**
    - Update `AL-Go-Settings.ps1`:
        ```json
        {
            "environments": [
                "OnPremiseTest",
                "OnPremiseProd (Production)"
            ],
            "DeployToOnPremiseTest": {
                "EnvironmentType": "OnPremise",
                "EnvironmentName": "test-onpremise"
            },
            "DeployToOnPremiseProd": {
                "EnvironmentType": "OnPremise",
                "EnvironmentName": "prod-onpremise"
            }
        }
        ```
    - The setting that links AL-Go to the custom deployment script is `"EnvironmentType": "OnPremise"`. If you want to use the customizable deployment script `DeployToOnPremiseCustom.ps1`, use the `"EnvironmentType": "OnPremiseCustom"`:
        ```json
        {
            "environments": [
                "OnPremiseTestCustom"
            ],
            "DeployToOnPremiseTestCustom": {
                "EnvironmentType": "OnPremiseCustom",
                "EnvironmentName": "test-onpremise",
                "ContinuousDeployment": false 
            }
        }
        ```

3. **authContext Secrets:**
    - Prepare `authContext` JSON, including the **apiBaseUrl** parameter:
        ```json
        {
            "clientId": "<client-id>",
            "clientSecret": "<client-secret>",
            "tenantId": "<tenant-id>",
            "environment": "<environment-name>",
            "apiBaseUrl": "http://your-onprem-instance-api-base-url/"
        }
        ```
    - `apiBaseUrl` is specific to AL-Go OnPremise Deployer and should be manually added to the `authContext` JSON. It should be the URL to  on-premise Business Central instance with the Automation API enabled and exposed.
    - Add `authContext` secrets to GitHub Action secrets or connected Azure Key Vault. Separate entries are required for each environment:
        ```markdown
        OnPremiseTest_authContext
        OnPremiseProd_authContext
        DeployToOnPremiseTestCustom_authContext
        ```

4. **Enable Automation API on Your On-Premise BC Instances:**
    - AL-Go OnPremise Deployer fully supports [ALOps-External-Deployer](https://github.com/HodorNV/ALOps-External-Deployer).
    - To enable the Automation API on your BC instances, follow the instructions in their [README](https://github.com/HodorNV/ALOps-External-Deployer).
    - Install ALOps-External-Deployer on each BC instance you want to deploy to
        ```bash
            install-module ALOps.ExternalDeployer -Force
            import-module ALOps.ExternalDeployer 
            Install-ALOpsExternalDeployer -ServerInstance test-onpremise
        ```

## 📊 Usage Statistics
To improve AL-Go OnPremise Deployer, we gather anonymized usage statistics:

- **What We Collect:** Anonymized user data (hashed GitHub username), repository information (hashed repository name), and deployment status (e.g., started, completed, failed).
- **Why We Collect It:** To enhance functionality, monitor performance, and guide development.
- **Opting Out:** Disable telemetry by adding `-DoNotSendTelemetry` when running the script. Consider using the customizable script [`DeployToOnPremiseCustom.ps1`](https://github.com/akoniecki/AL-Go-OnPremise-Deployer/blob/main/.github/DeployToOnPremiseCustom.ps1):
    ```powershell
        .github\DeployToOnPremise.ps1 -parameters $parameters -DoNotSendTelemetry
    ```

## 🌟 Contributing
We welcome contributions! Please read our [Contributing Guide](CONTRIBUTING.md) to get started and contribute to the project.

## 📜 License
This project is licensed under the MIT License. See the [LICENSE](LICENSE) file.

## 💬 Feedback & Issues
Share feedback and report issues [here](https://github.com/akoniecki/AL-Go-OnPremise-Deployer/issues).

## 🙌 Acknowledgements
- **Projects:**
    - [AL-Go for GitHub](https://github.com/microsoft/AL-Go): For providing the modern CI/CD foundational framework for Microsoft Dynamics 365 Business Central.
    - [BCContainerHelper](https://github.com/microsoft/navcontainerhelper): For invaluable tools and helper libraries.
    - [ALOps-External-Deployer](https://github.com/HodorNV/ALOps-External-Deployer): For enabling Automation API on on-premise Business Central instances.

## 📧 Contact
Reach out at [akoniecki@pm.me](mailto:akoniecki@pm.me) or connect on [LinkedIn](https://www.linkedin.com/in/akoniecki/).

**If you read the whole thing, give the project a Star! 🌟**