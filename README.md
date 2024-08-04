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
   - Copy the "Install/Update AL-Go OnPremise Deployer" workflow definition file to your repository.
     ```bash
     https://github.com/akoniecki/AL-Go-OnPremise-Deployer/blob/main/.github/workflows/OnPremiseDeployer.yaml
     ```
   - Ensure the filename is `OnPremiseDeployer.yaml` and place it in the correct path: `<your-repository>/.github/workflows`
   - Navigate to GitHub Actions in your repository, choose and run the "Install or Update AL-Go OnPremise Deployer" workflow.

2. **Using the Template:**
   - Click the "Use this template" button on the repository page and follow the wizard.

3. **Manual Copy:**
   - Manually copy the AL-Go OnPremise core files to your repository.

## 🛠️ Core Files
- **[`.github/DeployToOnPremise.ps1`](https://github.com/akoniecki/AL-Go-OnPremise-Deployer/blob/main/.github/DeployToOnPremise.ps1)**: Core script for handling on-premise environments deployment.
- **[`.github/workflows/OnPremiseDeployer.yaml`](https://github.com/akoniecki/AL-Go-OnPremise-Deployer/blob/main/.github/workflows/OnPremiseDeployer.yaml)**: GitHub Action for installing/updating AL-Go OnPremise Deployer.
- **[`.github/DeployToOnPremiseCustom.ps1`](https://github.com/akoniecki/AL-Go-OnPremise-Deployer/blob/main/.github/DeployToOnPremiseCustom.ps1)**: Customizable deployment script for adding specific logic or debugging.
- **[`.github/AL-Go-Settings.ps1`](https://github.com/akoniecki/AL-Go-OnPremise-Deployer/blob/main/.github/AL-Go-Settings.ps1)**: Template configuration file including deployment settings for different types of environments.

## 📈 Usage
To use the AL-Go OnPremise Deployer, follow these steps:

1. **Configure Your Environment:**
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
   - To activate/trigger AL-Go OnPremise Deployer during the deployment (CD) process, remember to put `"EnvironmentType": "OnPremise"` inside your DeployTo<YourEnvironmentName> setting.

2. **Configure AuthContext secret for the environment:**
   - TODO

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
