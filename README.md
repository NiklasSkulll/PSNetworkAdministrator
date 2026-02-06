```
╔═╗╔═╗╔╗╔╔═╗╔╦╗╦ ╦╔═╗╦═╗╦╔═
╠═╝╚═╗║║║║╣  ║ ║║║║ ║╠╦╝╠╩╗
╩  ╚═╝╝╚╝╚═╝ ╩ ╚╩╝╚═╝╩╚═╩ ╩
╔═╗╔╦╗╔╦╗╦╔╗╔╦╔═╗╔╦╗╦═╗╔═╗╔╦╗╔═╗╦═╗
╠═╣ ║║║║║║║║║║╚═╗ ║ ╠╦╝╠═╣ ║ ║ ║╠╦╝
╩ ╩═╩╝╩ ╩╩╝╚╝╩╚═╝ ╩ ╩╚═╩ ╩ ╩ ╚═╝╩╚═
```

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-blue.svg)](https://github.com/PowerShell/PowerShell)
[![PSEdition](https://img.shields.io/badge/PSEdition-Desktop%20%7C%20Core-blue.svg)](https://github.com/PowerShell/PowerShell)
[![Module Version](https://img.shields.io/badge/Version-0.1.0-brightgreen.svg)](PSNetworkAdministrator/PSNetworkAdministrator.psd1)
[![Pester Tests](https://img.shields.io/badge/Tests-Pester%205.0-brightgreen.svg)](Tests/Start-Tests.ps1)

---

# PSNetworkAdministrator

## Folder Structure

```
PSNetworkAdministrator/
├─ .gitignore
├─ README.md
├─ CODEOWNERS
├─ LICENSE
│
├─ src/
│  ├─ PSNetworkAdministrator/
│  │  ├─ PSNetworkAdministrator.psd1
│  │  ├─ PSNetworkAdministrator.psm1
│  │  ├─ Public/
│  │  ├─ Private/
│  │  │  ├─ Initialize-Configuration.ps1
│  │  │  ├─ Test-ExecutionContext.ps1
│  │  │  ├─ Test-OperatingSystem.ps1
│  │  │  ├─ Test-PowerShellVersion.ps1
│  │  │  ├─ Test-WpfAvailability.ps1
│  │  │  └─ Write-AppLogging.ps1
│  │  │
│  │  └─ Services/
│  │
│  └─ PSNetworkAdministrator.Gui/
│     ├─ Start-PSNetworkAdministrator.ps1
│     ├─ Views/
│     ├─ ViewModels/
│     ├─ Controls/
│     └─ Assets/
│
├─ config/
│  └─ config.psd1
│
├─ docs/
│  └─ PowerShell_Structure_Best_Practices.md
│
├─ tests/
│  ├─ unit/
│  ├─ integration/
│  └─ TestHelpers/
│
├─ logs/
│
├─ build/
│
├─ .config/
│
└─ .github/
```
