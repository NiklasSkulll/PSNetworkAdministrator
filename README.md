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
│
├── .config/                              # Configuration directory
├── .git/                                 # Git repository metadata
├── .github/                              # GitHub-specific files (currently empty)
├── .gitignore                            # Git ignore rules
│
├── build/                                # Build output directory (empty)
├── config/
│   └── config.psd1                       # PowerShell configuration data file
│
├── docs/
│   ├── PowerShell_Structure_Best_Practices.md
│   └── PSNetworkAdministrator_Tool_Plan.md
│
├── logs/                                 # Application logs directory
│
├── src/
│   ├── PSNetworkAdministrator/           # PowerShell Module
│   │   ├── PSNetworkAdministrator.psd1   # Module manifest
│   │   ├── PSNetworkAdministrator.psm1   # Module script file
│   │   ├── Private/                      # Internal helper functions
│   │   │   ├── Initialize-Configuration.ps1
│   │   │   ├── Test-ExecutionContext.ps1
│   │   │   └── Write-AppLogging.ps1
│   │   ├── Public/                       # Exported cmdlets (empty)
│   │   └── Services/                     # Service layer (empty)
│   │
│   └── PSNetworkAdministrator.Gui/       # WPF GUI Application (.NET 9.0)
│       ├── App.xaml                      # Application definition
│       ├── App.xaml.cs                   # Application code-behind
│       ├── AssemblyInfo.cs               # Assembly metadata
│       ├── PSNetworkAdministrator.Gui.csproj  # Project file
│       │
│       ├── converters/                   # XAML value converters
│       │   └── BoolToVisibilityConverter.cs
│       │
│       ├── models/                       # Data models (empty)
│       │
│       ├── viewmodels/                   # MVVM ViewModels
│       │   ├── DomainListViewModel.cs
│       │   ├── MainWindowViewModel.cs
│       │   ├── RelayCommand.cs
│       │   └── TitleBarViewModel.cs
│       │
│       ├── views/                        # XAML views
│       │   ├── DialogWindow.xaml / .cs
│       │   ├── DomainList.xaml / .cs
│       │   ├── MainWindow.xaml / .cs
│       │   └── TitleBar.xaml / .cs
│       │
│       ├── bin/Debug/net9.0-windows/     # Build output
│       └── obj/                          # Intermediate build files
│
├── tests/
│   ├── integration/                      # Integration tests (empty)
│   ├── unit/                             # Unit tests (empty)
│   └── TestHelpers/                      # Test utilities (empty)
│
├── CODEOWNERS                            # GitHub code ownership
├── LICENSE                               # License file
├── PSNetworkAdministrator.sln            # Visual Studio solution file
└── README.md                             # Project documentation
```
