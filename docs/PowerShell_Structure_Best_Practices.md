# PowerShell Structure Best Practices: PowerShell 7 + WPF

**Table of contents:**
- [Core idea: separate Product, Module, and App](#Core%20idea%20separate%20Product,%20Module,%20and%20App)
- [File types](#File%20types)
	- [1 `.psd1` - Manifest (metadata + exports)](#1%20`.psd1`%20-%20Manifest%20(metadata%20+%20exports))
	- [2 `.psm1` - Module entrypoint (loader)](#2%20`.psm1`%20-%20Module%20entrypoint%20(loader))
	- [3 `.ps1` - Function scripts and helper scripts](#3%20`.ps1`%20-%20Function%20scripts%20and%20helper%20scripts)
	- [4 `.xaml` - WPF UI markup](#4%20`.xaml`%20-%20WPF%20UI%20markup)
	- [5 Tests: `*.Tests.ps1` + optional `PesterConfiguration.psd1`](#5%20Tests%20`*.Tests.ps1`%20+%20optional%20`PesterConfiguration.psd1`)
	- [6 Lint: `PSScriptAnalyzerSettings.psd1`](#6%20Lint%20`PSScriptAnalyzerSettings.psd1`)
	- [7 `config/*.json`](#7%20`config/*.json`)
	- [8 Docs: `README.md`, `docs/*.md`](#8%20Docs%20`README.md`,%20`docs/*.md`)
- [Explanation of the usual folder splits](#Explanation%20of%20the%20usual%20folder%20splits)
	- [1 `src/` vs repo root](#1%20`src/`%20vs%20repo%20root)
	- [2 `Public/` and `Private/`](#2%20`Public/`%20and%20`Private/`)
	- [3 `Services/`](#3%20`Services/`)
	- [4 `tests/`](#4%20`tests/`)
	- [5 `build/`](#5%20`build/`)
- [Practical rule set: When to split a script into multiple files](#Practical%20rule%20set%20When%20to%20split%20a%20script%20into%20multiple%20files)
- [Minimal set of files you actually need](#Minimal%20set%20of%20files%20you%20actually%20need)
- [How GUI and admin logic should talk](#How%20GUI%20and%20admin%20logic%20should%20talk)
- [Best-practice guardrails you should enforce early](#Best-practice%20guardrails%20you%20should%20enforce%20early)
	- [Linting rules (`PSScriptAnalyzer`)](#Linting%20rules%20(`PSScriptAnalyzer`))
	- [Pester discovery rule](#Pester%20discovery%20rule)
- [Security model basics for admin tools](#Security%20model%20basics%20for%20admin%20tools)
- [Your "design it yourself" checklist](#Your%20"design%20it%20yourself"%20checklist)

---

## Core idea: separate Product, Module, and App

**3 layers:**
1. _Core module (engine):_
	- pure admin logic: functions that do work, return objects, can be tested headless.
2. _UI (WPF app):_
	- only user interaction + presentation (XAML + view-model-ish code), calls core module.
3. _Build / Test / Docs:_
	- everything needed to lint, test, package, run in CI.

This separation is what makes a project maintainable and testable.

---

## File types

### 1 `.psd1` - Manifest (metadata + exports)

| **Definition**                                                                                                                   | **Explanation**                                                                     |
| -------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------- |
| PowerShell hashtable file that describes the module: version, exported functions, required modules, compatible PS versions, etc. | enables predictable loading, packaging, dependency declaration, and export control. |

**Best practice:**
- explicitly export functions in the manifest (or in `psm1`), don’t rely on "everything in scope is exported".

### 2 `.psm1` - Module entrypoint (loader)

**Definition:**
- code that runs when the module is imported.

**What belongs here:**
- _only "composition" code:_
	- dot-source / load function files.
	- set strict mode.
	- initialize module-scoped services (logging / config).
	- export public commands.

**Best practice:**
- keep it thin so import is fast and side-effect free.

### 3 `.ps1` - Function scripts and helper scripts

**Definition:**
- script files.
- _in a module repo they’re usually either:_
	- functions (advanced functions you dot-source into the module) **or**
	- tools / build scripts (`build.ps1`, `package.ps1`) **or**
	- app entrypoints (`Start-*.ps1` for the GUI).

**Best practice:**
- one exported function per file is common because it keeps merges clean and code discoverable.

### 4 `.xaml` - WPF UI markup

**Definition:**
- declarative UI layout.

**Why split from code:**
- UI changes don’t mix with logic changes
- you can iterate visuals without touching admin code
- WPF + XAML loading patterns are well established.

### 5 Tests: `*.Tests.ps1` + optional `PesterConfiguration.psd1`

**Definition:**
- Pester recommends a test structure and warns about code running during discovery if placed outside blocks.
- it also documents configuration objects / recommended configuration creation patterns.

### 6 Lint: `PSScriptAnalyzerSettings.psd1`

**Definition:**
- `PSScriptAnalyzer` has an official set of rules and recommendations you can tune and enforce in CI.

### 7 `config/*.json`

| **Definition**                                                       | **Explanation**                                                       |
| -------------------------------------------------------------------- | --------------------------------------------------------------------- |
| runtime configuration that can be overridden per environment / user. | native in PowerShell (`ConvertFrom-Json`), easy to validate and ship. |

### 8 Docs: `README.md`, `docs/*.md`

**Definition:**
- "how to use", "how to extend", "security model", "architecture".

---

## Explanation of the usual folder splits

### 1 `src/` vs repo root

| **Definition**                                                                                            | **Explanation**                                                          |
| --------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------ |
| put product code under `src/` so the repo root can contain build / docs / CI without mixing runtime code. | CI and packaging become predictable (you can package only `src` output). |

### 2 `Public/` and `Private/`

**Definition:**
- _this is a very common pattern for script modules:_
	- public functions are exported.
	- private helpers are internal.

**Explanation:**
- prevents accidental exports.
- keeps your "API surface" small and stable.
- makes tests clearer (test public surface, unit-test internals only when needed).

### 3 `Services/`

| **Definition**                                                                                        | **Explanation**                                                          |
| ----------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------ |
| use this when you have cross-cutting concerns (logging, config, feature registry, elevation helpers). | otherwise logging / config code gets duplicated or sprinkled everywhere. |

### 4 `tests/`

| **Definition**                         | **Explanation**                                                       |
| -------------------------------------- | --------------------------------------------------------------------- |
| separate test code from shipping code. | packaging and deployment should never include test-only dependencies. |

### 5 `build/`

| **Definition**                              | **Explanation**                                           |
| ------------------------------------------- | --------------------------------------------------------- |
| Build scripts + dev dependencies live here. | prevents "random helper scripts" at root and supports CI. |

---

## Practical rule set: When to split a script into multiple files

**Split when at least one is true:**
1. _Public surface area:_
	- every exported function gets its own file.
		- easier discoverability and cleaner diffs.
2. _Different reasons to change:_
	- UI layout changes shouldn’t touch admin logic.
		- split XAML vs PowerShell view-model / services.
3. _Cross-cutting concerns:_
	- logging / config / elevation reused by many features.
		- put into `Services/`.
4. _Feature boundaries:_
	- new admin "feature" should be a folder (or even submodule).
	- reduces coupling and helps you ship increments.

Don’t split just for the sake of splitting: if you only have 3 functions, keep it simple.

---

## Minimal set of files you actually need

**If you want the smallest best-practice scaffold that still scales, it’s basically:**
- `src/<ModuleName>/<ModuleName>.psd1`
- `src/<ModuleName>/<ModuleName>.psm1`
- `src/<ModuleName>/Public/<Verb-Noun>.ps1`
- `src/<ModuleName>/Private/<helper>.ps1`
- `src/<GuiName>/Start-<GuiName>.ps1`
- `src/<GuiName>/Views/MainWindow.xaml`
- `src/<GuiName>/ViewModels/MainViewModel.ps1`
- `config/default.json`
- `tests/unit/.../*.Tests.ps1`
- `.config/PSScriptAnalyzerSettings.psd1`
- `build/build.ps1`
- `README.md`

Everything else is "nice to have".

---

## How GUI and admin logic should talk

**Golden rule:**
- UI never "does admin work".
- _It only:_
	- gathers inputs.
	- calls a public function in the core module.
	- displays returned objects / errors.
- so your core module should return objects, not formatted strings. UI decides how to display.

**WPF patterns in PowerShell vary:**
- MVVM-style (ViewModel + command bindings) is popular because it avoids "button click spaghetti".

---

## Best-practice guardrails you should enforce early

### Linting rules (`PSScriptAnalyzer`)

**Definition:**
- use an analyzer settings file and run it in CI.

**Information:**
- Microsoft’s "rules and recommendations" page is current and a good baseline.
- [Microsoft Learn](https://learn.microsoft.com/en-us/powershell/utility-modules/psscriptanalyzer/rules-recommendations?view=ps-modules&utm_source=chatgpt.com "PSScriptAnalyzer rules and recommendations - PowerShell")

### Pester discovery rule

**Definition:**
- no "work" at top-level in tests
- put code inside `Describe/Context/It`, otherwise it runs during discovery.

---

## Security model basics for admin tools

- _Least privilege by default:_
	- run unelevated.
	- elevate only for actions that require it (and isolate those actions).
- _Credentials:_
	- prefer Windows integrated auth / current token.
	- if you must store secrets, use Windows DPAPI (e.g., `Export-CliXml` with secure string is user/machine scoped) or Windows Credential Manager - never plain text in config.
- _Elevation:_
	- treat it as a feature (a service helper), not scattered `Start-Process -Verb RunAs` everywhere.
- _Logging:_
	- avoid writing secrets or PII.
	- log intent, timing, outcome, correlation IDs.

---

## Your "design it yourself" checklist

**If you want to build your own structure confidently, decide these up front:**
1. What is the public API? (exported functions)
2. What are the cross-cutting services? (config, logging, elevation, telemetry)
3. What is the feature unit? (folder per feature, or submodule per feature)
4. How will you test? (unit vs integration; CI gates)
5. How will you package? (zip, MSI, PS Gallery / private repo)

---

## Planned Script Structure

```
PSNetworkAdministrator/
├─ README.md
│
├─ src/
│  ├─ PSNetworkAdministrator/
│  │  ├─ PSNetworkAdministrator.psd1    # manifest
│  │  ├─ PSNetworkAdministrator.psm1    # module entrypoint/loader
│  │  ├─ Public/
│  │  ├─ Private/
│  │  ├─ Services/
│  │  └─ Resources/    # maybe later for localization or static assets
│  │
│  └─ PSNetworkAdministrator.Gui/
│     ├─ Start-PSNetworkAdministrator.ps1    # start the app(imports the module and launches the WPF window)
│     ├─ Views/
│     │  └─ MainWindow.xaml
│     │
│     ├─ ViewModels/
│     │  └─ MainViewModel.ps1
│     │
│     ├─ Controls/
│     └─ Assets/
│
├─ config/
│  └─ default.json    # runtime defaults
│
├─ docs/
│
├─ tests/
│  ├─ unit/
│  ├─ integration/
│  └─ TestHelpers/
│     └─ Import-NotRepTest.ps1    # avoids repeating import logic in every test
│
├─ build/
│  └─ build.ps1    # runs PSScriptAnalyzer and Pester
│
├─ .config/
│  └─ PSScriptAnalyzerSettings.psd1    # lint rules
│
└─ .github/
```
