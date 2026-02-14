# PSNetworkAdministrator Tool: Plan

**Table of contents:**
- [Technology](#Technology)
- [Running PowerShell with C-Sharp](#Running%20PowerShell%20with%20C-Sharp)
- [Current structure and planned structure](#Current%20structure%20and%20planned%20structure)
	- [Current structure](#Current%20structure)
	- [Planned structure](#Planned%20structure)
- [Further steps](#Further%20steps)
	- [1 Create the WPF project](#1%20Create%20the%20WPF%20project)
	- [2 Decide the runtime "deployment layout"](#2%20Decide%20the%20runtime%20"deployment%20layout")
- [Feature Plan](#Feature%20Plan)

---

## Technology

| **Tool**   | **Version**                      | **Usage**                                                   |
| ---------- | -------------------------------- | ----------------------------------------------------------- |
| PowerShell | `Microsoft.PowerShell.SDK 7.5.4` | backend, as the "engine"                                    |
| C#         | `.NET 9`                         | frontend, for a maintainable, scalable UI (real MVVM, etc.) |
| WPF        | `net9.0-windows`                 | frontend, UI-Tool                                           |

---

## Running PowerShell with C-Sharp

**Host PowerShell inside the WPF app (in-process):**
- add the `PowerShell SDK NuGet package` and run the module in a runspace.
- Microsoft explicitly describes "hosting" PowerShell in .NET apps and which NuGet packages to use: [Microsoft Learn](https://learn.microsoft.com/en-us/powershell/scripting/dev-cross-plat/choosing-the-right-nuget-package?view=powershell-7.5&utm_source=chatgpt.com "Choosing the right PowerShell NuGet package for your .NET project")

| **Pros**                                                  | **Cons**                                                                 |
| --------------------------------------------------------- | ------------------------------------------------------------------------ |
| single EXE deployment is easier.                          | `.NET target framework` must be aligned with the PowerShell SDK version. |
| control the PS engine version via NuGet.                  |                                                                          |
| no dependency on `pwsh installed` (unless it's required). |                                                                          |

---

## Current structure and planned structure

### Current structure

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

**The PowerShell Module and engine is already separated from the UI in the `src/`-folder:**
- `src/PSNetworkAdministrator/` (module / engine)
- `src/PSNetworkAdministrator.Gui/` (UI shell)

### Planned structure

```
PSNetworkAdministrator/
├─ .gitignore
├─ README.md
├─ CODEOWNERS
├─ LICENSE
│
├─ src/
│  ├─ PSNetworkAdministrator/          # PowerShell module (engine)
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
│  └─ PSNetworkAdministrator.Gui/      # C# WPF project root (contains .csproj)
│     ├─ PSNetworkAdministrator.Gui.csproj
│     ├─ App.xaml
│     ├─ Views/
│     ├─ ViewModels/
│     ├─ Controls/
│     ├─ Assets/
│     └─ Services/
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

**Planned changes:**
- the `PSNetworkAdministrator.Gui` becomes a real C# WPF project.

---

## Further steps

### 1 Create the WPF project

**Create the WPF project at `src/PSNetworkAdministrator.Gui`:**
- _because the plan is `.NET 9` + `PS SDK 7.5.4`, do:_
```powershell
dotnet new wpf -n PSNetworkAdministrator.Gui -o .\src\PSNetworkAdministrator.Gui -f net9.0-windows
```

```powershell
cd .\src\PSNetworkAdministrator.Gui
```

```powershell
dotnet add package Microsoft.PowerShell.SDK --version 7.5.4
```

### 2 Decide the runtime "deployment layout"

**Recommended layout in output folder (so the C# app can import reliably):**
- `.\Modules\PSNetworkAdministrator\PSNetworkAdministrator.psd1`
- `.\config\config.psd1`

Then the C# `ModuleLocator` builds paths from `AppContext.BaseDirectory`.

---

## Feature Plan

**What should this App can do?**
- _Domain-Detection:_
	- detect, if the user/pc, which is starting the app, is in a Domain:
		- if not in a Domain, user should add an Domain:
			- type in the name of the name.
- _Domain-Adding:_
	- possible to administrate multiple Domains, by adding them (User-Input).
- _Domain-Authentication:_
	- "login" as Domain-Administrator for advanced powershell-commands (credentials for safety).
	- only when necessary.
- _Overview:_
	- How many servers are in this Domain? (how many online/offline?)
	- How many clients are in this Domain? (how many online/offline?)
	- How many users are in this Domain?
	- How many policies are in the Domain?
- _Server-List:_
	- list all Server from a Domain (online and offline Server).
	- list with IP, servernames (DNS-Names), offline/online-status, system-infos: storage, RAM, CPU, Update available (check current OS version and compare with the newest available one) etc.
- _Client-List:_
	- list all clients from a Domain (online and offline Server).
	- list with IP, clientnames (DNS-Names), offline/online-status, system-infos: storage, RAM, CPU, etc.
- _User-List:_
	- list all users from a Domain.
	- list with policies-ID.
	- group users by the department (metadata from user) (like Order, Sales, etc.)
	- option to add new users to AD
- _Policies-List:_
	- Which policies are active?
	- list policies with ID, context (user, computer), which kind of policy? (Security, etc.)
	- Option to create a new policy
- _DNS/AD/DHCP-Administration:_
	- administrate the network.
