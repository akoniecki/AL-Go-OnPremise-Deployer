# AL-Go OnPremise Deployer 🚀

## Overview
**AL-Go OnPremise Deployer** extends the functionality of [AL-Go for GitHub](https://github.com/microsoft/AL-Go) to enable deployment to Business Central’s on-premise environments, which was previously limited to Business Central Online (SaaS).

![Seamless integration with AL-Go](https://i.pinimg.com/originals/4f/7e/ab/4f7eab8b98913e658391c54b57980e68.gif)

[![CI/CD Status](https://img.shields.io/github/actions/workflow/status/akoniecki/AL-Go-OnPremise-Deployer/CICD.yml)](https://github.com/akoniecki/AL-Go-OnPremise-Deployer/actions)
[![License](https://img.shields.io/github/license/akoniecki/AL-Go-OnPremise-Deployer)](LICENSE)
[![Contributor Covenant](https://img.shields.io/badge/Contributor%20Covenant-2.1-4baaaa.svg)](CODE_OF_CONDUCT.md)

## Table of Contents
- [Features](#-features)
- [Installation Methods](#-installation-methods)
- [Core Files](#-core-files)
- [Additional Files](#additional-files)
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

## 📥 Installation Methods
1. **Using the Workflow Definition File:**
    - Download the "Install/Update AL-Go OnPremise Deployer" workflow definition file:
        ```bash
        https://github.com/akoniecki/AL-Go-OnPremise-Deployer/blob/main/.github/workflows/OnPremiseDeployer.yaml
        ```
    - Ensure the filename is `OnPremiseDeployer.yaml` and place it in the correct path within your AL-Go repository: `<your-repository>/.github/workflows`
    - Ensure the `ghWorkflowToken` secret is available for your AL-Go repository (more info in the Usage section).
    - Navigate to GitHub Actions in your repository and run the "Install or Update AL-Go OnPremise Deployer" workflow.
    - The workflow will install or update AL-Go OnPremise Deployer core files and create a Pull Request with changes that you need to review and merge.
    - AL-Go OnPremise Deployer's additional files need to be added manually if needed, and these files won't be updated/overwritten by the update workflow.

2. **Using the Repository Template:**
    - Click the "Use this template" button on the repository page and follow the wizard to create your own repository based on this one.

3. **Offline Installation:**
    - Just copy the AL-Go OnPremise **core files** to your AL-Go repository. Additionally, you can include our **additional files**, such as setting template for a quick start or customizable deployment script for more advanced cases.

## 🛠️ Core Files
    - **[`.github/DeployToOnPremise.ps1`](https://github.com/akoniecki/AL-Go-OnPremise-Deployer/blob/main/.github/DeployToOnPremise.ps1)**: Core script for handling on-premise environments deployment.
    - **[`.github/workflows/OnPremiseDeployer.yaml`](https://github.com/akoniecki/AL-Go-OnPremise-Deployer/blob/main/.github/workflows/OnPremiseDeployer.yaml)**: GitHub Action for installing/updating AL-Go OnPremise Deployer.

## 🧰 Additional Files
    - **[`.github/DeployToOnPremiseCustom.ps1`](https://github.com/akoniecki/AL-Go-OnPremise-Deployer/blob/main/.github/DeployToOnPremiseCustom.ps1)**: Customizable deployment script for adding specific logic or debugging.
    - **[`.github/AL-Go-Settings.ps1`](https://github.com/akoniecki/AL-Go-OnPremise-Deployer/blob/main/.github/AL-Go-Settings.ps1)**: Template configuration file including deployment settings for different types of environments.

## 📈 Usage
To use the AL-Go OnPremise Deployer, follow these steps:

1. **Check AL-Go's ghWorkflowToken Secret:**
    - Before you run the installation/update script [OnPremiseDeployer.yaml](https://github.com/akoniecki/AL-Go-OnPremise-Deployer/blob/main/.github/workflows/OnPremiseDeployer.yaml), ensure you have a valid **ghWorkflowToken** secret available in your AL-Go repository (GitHub Action secrets or connected Azure Key Vault).
    - AL-Go OnPremise Deployer utilizes the AL-Go's built-in secret ghWorkflowToken. To read more about how to create one, please follow the [AL-Go repository docs](https://github.com/microsoft/AL-Go/blob/main/Scenarios/UpdateAlGoSystemFiles.md).
        ```markdown
            4. To update the AL-Go system files using the Update AL-Go System Files workflow, you need to provide a secret called GHTOKENWORKFLOW containing a Personal Access Token with permissions to modify workflows. Personal access tokens are either fine-grained personal access tokens or classic personal access tokens. AL-Go for GitHub works with both
        ```

2. **Enable AL-Go OnPremise Deployer Automatic Updates:**
    - To enable automatic updates for the AL-Go OnPremise Deployer, you need to configure the `UpdateOnPremiseDeployerSchedule` in your `AL-Go-Settings.ps1` file.
    - This setting allows you to define a cron schedule for the automatic update workflow.
    Example configuration in `AL-Go-Settings.ps1`:
        ```markdown
            "UpdateOnPremiseDeployerSchedule": "0 19 * * 2"
        ```   
    - The UpdateOnPremiseDeployerSchedule field uses cron syntax to define when the update workflow should run. In this example, the workflow is scheduled to run every Tuesday at 19:00.

3. **Configure Your GitHub Environments:**
    - Update your `AL-Go-Settings.ps1` file to include the on-premise environments you wish to deploy to.
        ```json
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
        ```
    - The setting that links AL-Go to custom deployment script is `"EnvironmentType": "OnPremise"`. If you want to use the customizable deployment script `DeployTo**OnPremiseCustom**.ps1`, use the `"EnvironmentType": "**OnPremiseCustom**"`.
        ```json
            "environments": [
                "OnPremiseTestCustom"
            ],
            "DeployToOnPremiseTestCustom": {
                "EnvironmentType": "OnPremiseCustom",
                "EnvironmentName": "test-onpremise",
                "ContinuousDeployment": false 
            }
        ```

4. **Configure authContext Secrets for Your Environments:**
    - TODO: **apiBaseUrl** parameter in authContext
        ```json
            {apiBaseUrl}
        ```
    - TODO: How to compose proper authContext secret, links to ms docs
    - Add authContext secrets to your GitHub Action secrets or connected Azure Key Vault. Separate entry is required for each environment.
        ```markdown
            OnPremiseTest_authContext
            OnPremiseProd_authContext
            DeployToOnPremiseTestCustom_authContext
        ```

5. **Enable Automation API on Your On-Premise BC Instances:**
    - AL-Go OnPremise Deployer fully supports [ALOps-External-Deployer](https://github.com/HodorNV/ALOps-External-Deployer).
    - To enable Automation API on your BC instances, follow the instructions provided in their [README](https://github.com/HodorNV/ALOps-External-Deployer).
    - Remember to install ALOps-External-Deployer on each BC instance you want to deploy to.
        ```bash
            install-module ALOps.ExternalDeployer -Force
            import-module ALOps.ExternalDeployer 
            Install-ALOpsExternalDeployer -ServerInstance test-onpremise
        ```

## 📊 Usage Statistics
To help us improve AL-Go OnPremise Deployer, we gather anonymized usage statistics. Here’s what we collect and why:

1. **What We Collect:**
    - **Anonymized User Data:** A hash of your GitHub username to track unique users without revealing your identity.
    - **Repository Information:** A hash of your repository name to understand the spread and usage across different projects.
    - **Status Information:** Deployment status (e.g., started, completed, failed) to monitor the success and failure rates of deployments.

2. **Why We Collect It:**
    - **Improve Functionality:** Understand how the tool is being used and identify areas for improvement.
    - **Monitor Performance:** Track success and failure rates to ensure reliable performance.
    - **Guide Development:** Prioritize features and enhancements based on actual usage patterns.

3. **Opting Out:**
    - If you prefer not to send usage statistics, you can disable telemetry by adding the `-DoNotSendTelemetry` switch when running the deployment script. In such case consider using customizable script [`DeployToOnPremiseCustom.ps1`](https://github.com/akoniecki/AL-Go-OnPremise-Deployer/blob/main/.github/DeployToOnPremiseCustom.ps1).
        ```powershell
            .github\DeployToOnPremise.ps1 -parameters $parameters -DoNotSendTelemetry
        ```

## 🌟 Contributing
We welcome contributions! Please read our [Contributing Guide](CONTRIBUTING.md) to get started and contribute to the project.

## 📜 License
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 💬 Feedback & Issues
Don't hesitate to share your feedback and report [issues here](https://github.com/akoniecki/AL-Go-OnPremise-Deployer/issues).

## 🙌 Acknowledgements
    - **Projects:**
        - [AL-Go for GitHub](https://github.com/microsoft/AL-Go): For providing the modern CI/CD foundational framework for Microsoft Dynamics 365 Business Central.
        - [BCContainerHelper](https://github.com/microsoft/navcontainerhelper): For invaluable tools and helper libraries.
        - [ALOps-External-Deployer](https://github.com/HodorNV/ALOps-External-Deployer): For enabling Automation API on on-premise Business Central instances.

## 📧 Contact
Feel free to reach out directly at [akoniecki@pm.me](mailto:akoniecki@pm.me) or connect on [LinkedIn](https://www.linkedin.com/in/akoniecki/).

**If you read the whole thing, give the project a Star! 🌟**