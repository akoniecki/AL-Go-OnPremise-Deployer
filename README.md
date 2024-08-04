# AL-Go OnPremise Deployer 🚀

## Overview
**AL-Go OnPremise Deployer** extends the functionality of [AL-Go for GitHub](https://github.com/microsoft/AL-Go) to enable deployment to Business Central’s on-premise environments, previously limited to Business Central Online (SaaS).

![Seamless integration with AL-Go](https://i.pinimg.com/originals/4f/7e/ab/4f7eab8b98913e658391c54b57980e68.gif)

[![CI/CD Status](https://img.shields.io/github/actions/workflow/status/akoniecki/AL-Go-OnPremise-Deployer/CICD.yml)](https://github.com/akoniecki/AL-Go-OnPremise-Deployer/actions)
[![License](https://img.shields.io/github/license/akoniecki/AL-Go-OnPremise-Deployer)](LICENSE)

## 🚀 Features
- **On-Premise Deployment:** Easily deploy Business Central's AL extensions to on-premise environments.
- **AL-Go for Github:** Seamless integration with [AL-Go for GitHub](https://github.com/microsoft/AL-Go), enabled by "custom deployment scripts" build-in feature.
- **Automation API:** No GitHub Agent installation required. The modern deployment process uses Business Central's Automation API.
- **Easy installation:** Simply add [OnPremiseDeployer.yml](https://github.com/akoniecki/AL-Go-OnPremise-Deployer/blob/main/.github/workflows/OnPremiseDeployer.yaml) workflow file to your repository and run it.
- **Automatic updates:** New "UpdateOnPremiseDeployerSchedule" setting to enable automatic updates schedule.

## 📥 Installation Methods
1. Copy the "Install/Update AL-Go OnPremise Deployer" workflow definition file to your repository.
   ```bash
   https://github.com/akoniecki/AL-Go-OnPremise-Deployer/blob/main/.github/workflows/OnPremiseDeployer.yaml
   ```
   Note: keep the source filename "OnPremiseDeployer.yml" and ensure the correct path: <your-repository>/.github/workflows
   Navigate to GitHub Actions in your repository, choose and run "Install or Update AL-Go OnPremise Deployer" workflow
2. Create a repository from template 
   ```bash
   Click "Use this template" button and follow the wizard.
   ```
3. Manually copy AL-Go OnPremise core files to your repository

## 🛠️ Core Files
- **`.github/DeployToOnPremise.ps1`**: The core script for deploying to on-premise environments.
- **`.github/workflows/OnPremiseDeployer.yaml`
- **`.github/DeployToOnPremiseCustom.ps1`**: Customizable deployment script to add specific logic or for debugging.
- **`.github/AL-Go-Settings.ps1`**: Template configuration file, including deployment settings for different types of environments

## 📈 Usage


## 🌟 Contributing
Please read our [Contributing Guide](CONTRIBUTING.md) to get started and contribute to the project.

## 📜 License
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 💬 Feedback & issues
Don't hesitate to share your feedback and report issues here: [Issues](https://github.com/akoniecki/AL-Go-OnPremise-Deployer/issues)


## 🙌 Acknowledgements
- [AL-Go for GitHub](https://github.com/microsoft/AL-Go)
- [BCContainerHelper](https://github.com/microsoft/navcontainerhelper)
- [ALOps-External-Deployer](https://github.com/HodorNV/ALOps-External-Deployer)

## 📧 Contact
Feel free to reach me out directly at [akoniecki@pm.me](mailto:akoniecki@pm.me) or [LinkedIn](https://www.linkedin.com/in/akoniecki/).
