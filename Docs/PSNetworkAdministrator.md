# PSNetworkAdministrator

A single-entry PowerShell script providing a text‑based menu to administer your Windows network without using GUI tools.

---

## Table of Contents

1. [Features](#features)
2. [Prerequisites](#prerequisites)
3. [Structure](#structure)
4. [Usage](#usage)
5. [Core Script](#core-script)
6. [Menu Functions](#menu-functions)
7. [Modules](#modules)
8. [Logging & Error Handling](#logging--error-handling)
9. [Test Environment](TestEnvironment.md)

---

## Features

- Single script entry point (no parameters required)
- Interactive menu with numbered and lettered options:
    1. User Management   
    2. Computer Management
    3. Group Management    
    4. Network Diagnostics
    5. DNS Management
    6. DHCP Information
    7. Domain Controller Info
    8. Security and Audit
    9. System Health Check
    10. Change Domain  
        H. Help  
        Q. Quit
- Modular design: each menu item calls a dedicated function or module
- Centralized logging and error handling

---

## Prerequisites

- PowerShell 5.1 or newer
- Windows Server 2016+ or Windows 10+
- PowerShell Remoting enabled
- Modules installed under `. Modules\`:
    - `UserManagement`
    - `ComputerManagement`
    - `GroupManagement`
    - `Diagnostics`
    - `DNS`
    - `DHCPInfo`
    - `DomainController`
    - `SecurityAudit`
    - `HealthCheck`
    - `DomainSwitch`

---

## Structure

```text
PSNetworkAdministrator/
├── .git/                          ← Git metadata (auto-created)
├── .github/                       ← GitHub config (CI, issue templates, etc.)
│   └── ISSUE_TEMPLATE/
│       ├── documentation.yml
│       ├── feature_request.yml
│       └── refactoring.yml
├── Build/                         ← Build‐and-package scripts (e.g. build.ps1, versioning)
├── Docs/                          ← User-facing documentation, architecture diagrams
│   └── PSNetworkAdministrator.md
├── PSNetworkAdministrator/        ← Core PowerShell modules & public interface
│   ├── Classes/                   ← Helper classes (e.g. custom PSCustomObject types)
│   │   └── *.ps1
│   ├── Private/                   ← Internal helper scripts (e.g. shared functions)
│   │   └── *.ps1
│   └── Public/                    ← Exposed cmdlets & entry-point
│       ├── Invoke-PSNetworkAdmin.ps1  ← main script (shows menu)
│       └── *.psm1                     ← module files (UserManagement.psm1, DNS.psm1…)
├── Tests/                         ← Pester tests, one file per module
│   └── *.Tests.ps1
├── Logs/                          ← Runtime logs (gitignored)
│   └── PSNetworkAdmin_*.log
├── .gitignore                     ← ignore build artifacts, logs, etc.
├── CODEOWNERS                     ← who “owns” which paths
├── LICENSE                        ← project license
├── README.md                      ← overview + quickstart
└── CHANGELOG.md                   ← version history (Keep a Changelog format)

```

---

## Usage

1. Clone or download the repository
2. From an elevated PowerShell prompt, run:
    ```powershell
    Set-ExecutionPolicy Bypass -Scope Process
    .\Scripts\PSNetworkAdministrator.ps1
    ```
3. The menu appears. Enter the number or letter for the desired action and press **Enter**.

---

## Menu Functions

Each `Invoke-*` function should reside in its respective module under `Modules\` and implement functionality with clear logging and error handling.

---

## Modules

- **UserManagement**: Create, modify, remove AD users
- **ComputerManagement**: Join/remove machines from domain, rename, reboot
- **GroupManagement**: Manage AD groups and memberships
- **Diagnostics**: Ping, tracert, port checks
- **DNS**: Query and update DNS records
- **DHCPInfo**: Show lease scopes and statistics
- **DomainController**: Health, replication status
- **SecurityAudit**: Event log analysis, audit policy
- **HealthCheck**: Disk, CPU, memory, service status
- **DomainSwitch**: Change domain context or credentials

---

## Logging & Error Handling

- Central `Write-Log(message, level)` writes to `Logs\PSNetworkAdmin_YYYYMMDD.log`
- Use `Try/Catch` around critical operations
- Write errors to log with 'Error' level and display friendly message
