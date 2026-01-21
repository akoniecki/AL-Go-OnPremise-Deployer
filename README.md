# AL-Go OnPremise Deployer 🚀

## Overview
**AL-Go OnPremise Deployer** extends [AL-Go for GitHub](https://github.com/microsoft/AL-Go) to enable deployment to Business Central’s on-premise environments, previously limited to SaaS.

![Integration with AL-Go](https://i.ibb.co/wsZ2LDx/al-go-onpremise-deployer-img1.png)

[![CI/CD Status](https://img.shields.io/github/actions/workflow/status/akoniecki/AL-Go-OnPremise-Deployer/CICD.yaml)](https://github.com/akoniecki/AL-Go-OnPremise-Deployer/actions)

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
- **AL-Go for GitHub Integration:** Seamless integration with [AL-Go for GitHub](https://github.com/microsoft/AL-Go) using built-in custom deployment scripts.
- **Automation API:** No GitHub Agent required — the modern deployment process leverages Business Central's Automation API.
- **Easy Installation:** Simply add the [OnPremiseDeployer.yaml](https://github.com/akoniecki/AL-Go-OnPremise-Deployer/blob/main/.github/workflows/OnPremiseDeployer.yaml) workflow file to your AL-Go repository and run it.
- **Automatic Updates:** Use the new `UpdateOnPremiseDeployerSchedule` setting in `AL-Go-Settings.json` to schedule automatic updates.

## 📥 Installation
1. **Using the Workflow File:**
    - Download and place the [OnPremiseDeployer.yaml](https://github.com/akoniecki/AL-Go-OnPremise-Deployer/blob/main/.github/workflows/OnPremiseDeployer.yaml) file in the `.github/workflows` directory of your AL-Go repository.
    - Ensure you have a valid `GhTokenWorkflow` secret set up in your AL-Go repository. See [AL-Go docs](https://github.com/microsoft/AL-Go/blob/main/Scenarios/UpdateAlGoSystemFiles.md) for more information.
    - Run the "Install or Update AL-Go OnPremise Deployer" workflow in GitHub Actions.

2. **Using the Repository Template:**
    - Click "Use this template" on the repository page and follow the wizard.

3. **Offline Installation:**
    - Just copy the AL-Go OnPremise **core files** to your AL-Go repository. You can also include **additional files** for quick start settings or customizable deployment script for more advanced cases.

## 🛠️ Core Files
- **[`.github/DeployToOnPremise.ps1`](https://github.com/akoniecki/AL-Go-OnPremise-Deployer/blob/main/.github/DeployToOnPremise.ps1)**: The core script for handling on-premise deployments.
- **[`.github/workflows/OnPremiseDeployer.yaml`](https://github.com/akoniecki/AL-Go-OnPremise-Deployer/blob/main/.github/workflows/OnPremiseDeployer.yaml)**: GitHub Action for installing/updating AL-Go OnPremise Deployer.

## 🧰 Additional Files
- **[`.github/DeployToOnPremiseCustom.ps1`](https://github.com/akoniecki/AL-Go-OnPremise-Deployer/blob/main/.github/DeployToOnPremiseCustom.ps1)**: A customizable on-premise deployment script.
- **[`.github/AL-Go-Settings.ps1`](https://github.com/akoniecki/AL-Go-OnPremise-Deployer/blob/main/.github/AL-Go-Settings.ps1)**: A template configuration file.

## 📈 Usage    
1. **Automatic Updates:**
    - Set up the `UpdateOnPremiseDeployerSchedule` in `AL-Go-Settings.json`:
        ```json
        {
            "UpdateOnPremiseDeployerSchedule": "0 19 * * 2"
        }
        ```
    - Run the "Install or Update AL-Go OnPremise Deployer" workflow to apply scheduler changes.

2. **Configure Environments:**
    - Update `AL-Go-Settings.json` with your on-premise environments:
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
    - The key that links AL-Go to the custom deployment script is `"EnvironmentType": "OnPremise"`. If you prefer to use the customizable deployment script `DeployToOnPremiseCustom.ps1`, set `"EnvironmentType": "OnPremiseCustom"`:
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
    - Prepare your `authContext` JSON, ensuring it is compressed without any whitespaces, and include the **apiBaseUrl** parameter:
        ```json
        {"clientId":"<client-id>","clientSecret":"<client-secret>","tenantId":"<tenant-id>","apiBaseUrl":"<https://yourOnPremBcServer.westeurope.cloudapp.azure.com>"}
        ```
    - In case of using Basic Authentication, ensure `authContext` includes **Username** and **Password** parameters:
        ```json
        {"Username":"<bc-username>","Password":"<webservice-access-key>","apiBaseUrl":"<https://yourOnPremBcServer.westeurope.cloudapp.azure.com>"}
        ```
    - The `apiBaseUrl` is specific to AL-Go OnPremise Deployer and must be manually added to the `authContext` JSON. This should point to your on-premise Business Central instance with the Automation API enabled and exposed.
    - Add `authContext` secrets to your GitHub Action secrets or connected Azure Key Vault. Separate entries are needed for each environment:
        ```markdown
        OnPremiseTest_authContext
        OnPremiseProd_authContext
        DeployToOnPremiseTestCustom_authContext
        ```

4. **Enable Automation API on Your On-Premise BC Instances:**
    - AL-Go OnPremise Deployer fully supports [ALOps-External-Deployer](https://github.com/HodorNV/ALOps-External-Deployer).
    - To enable the Automation API on your BC instances, follow the instructions in [ALOps External Deployer's README](https://github.com/HodorNV/ALOps-External-Deployer).
    - Install ALOps-External-Deployer on each BC instance you want to deploy to:
        ```bash
            install-module ALOps.ExternalDeployer -Force
            import-module ALOps.ExternalDeployer 
            Install-ALOpsExternalDeployer -ServerInstance test-onpremise
        ```
    - In case of using Entra ID authentication, be sure to register your app in Entra ID (Azure AD) to obtain the authContext credentials (ClientID, ClientSecret, and TenantID), and configure your BC instance for Entra ID authentication.
    
## 📊 Usage Statistics
To improve AL-Go OnPremise Deployer, anonymized usage data is collected:

- **What We Collect:** Anonymized user data (hashed GitHub username), repository information (hashed repository name), and deployment status (e.g., started, completed, failed).
- **Why We Collect It:** To enhance functionality, monitor performance, and guide development.
- **Opting Out:** Disable telemetry by adding `-DoNotSendTelemetry` when running the script. Consider using the customizable script [`DeployToOnPremiseCustom.ps1`](https://github.com/akoniecki/AL-Go-OnPremise-Deployer/blob/main/.github/DeployToOnPremiseCustom.ps1):
    ```powershell
        .github\DeployToOnPremise.ps1 -parameters $parameters -DoNotSendTelemetry
    ```

## 🌟 Contributing
Have ideas or improvements? Check out [Contributing Guide](CONTRIBUTING.md) and jump right in!

## 📜 License
This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## 💬 Feedback & Issues
Have feedback or found an issue? Share it [here](https://github.com/akoniecki/AL-Go-OnPremise-Deployer/issues) or contact directly.

## 🙌 Acknowledgements
- **Projects:**
    - [AL-Go for GitHub](https://github.com/microsoft/AL-Go): For providing the modern CI/CD foundation for Microsoft Dynamics 365 Business Central.
    - [BCContainerHelper](https://github.com/microsoft/navcontainerhelper): For invaluable tools and helper libraries.
    - [ALOps-External-Deployer](https://github.com/HodorNV/ALOps-External-Deployer): For enabling Automation API on on-premise Business Central instances.

## 📧 Contact
Reach out at [akoniecki@pm.me](mailto:akoniecki@pm.me) or connect on [LinkedIn](https://www.linkedin.com/in/akoniecki/).


**Got this far? Your Star can help this project shine! 🌟**
