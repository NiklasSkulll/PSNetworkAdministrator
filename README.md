```
╔═╗╔═╗╔╗╔╔═╗╔╦╗╦ ╦╔═╗╦═╗╦╔═
╠═╝╚═╗║║║║╣  ║ ║║║║ ║╠╦╝╠╩╗
╩  ╚═╝╝╚╝╚═╝ ╩ ╚╩╝╚═╝╩╚═╩ ╩
╔═╗╔╦╗╔╦╗╦╔╗╔╦╔═╗╔╦╗╦═╗╔═╗╔╦╗╔═╗╦═╗
╠═╣ ║║║║║║║║║║╚═╗ ║ ╠╦╝╠═╣ ║ ║ ║╠╦╝
╩ ╩═╩╝╩ ╩╩╝╚╝╩╚═╝ ╩ ╩╚═╩ ╩ ╩ ╚═╝╩╚═
```

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![PowerShell](https://img.shields.io/badge/PowerShell-7.5.4-blue.svg)](https://github.com/PowerShell/PowerShell)
[![.NET](https://img.shields.io/badge/.NET-9.0-purple.svg)](https://dotnet.microsoft.com/)
[![Module Version](https://img.shields.io/badge/Version-1.0.0-brightgreen.svg)](src/PSNetworkAdministrator/PSNetworkAdministrator.psd1)
[![GUI Framework](https://img.shields.io/badge/GUI-WPF%20%7C%20Material%20Design-blueviolet.svg)](src/PSNetworkAdministrator.Gui/)

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
