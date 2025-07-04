# GitHub Copilot: PowerShell Network Administration Script Comments Enhancement

## Project Context

You are enhancing the script library for `PSNetworkAdministrator`, a PowerShell-based toolkit designed to automate the administration of an entire Windows network: Active Directory, Group Policy, DNS, DHCP, software deployment, health checks, and security auditing.

## Core Commenting Philosophy

CLARITY & MAINTAINABILITY
- Add concise, professional comments that reveal the “why” and complex “how” without cluttering straightforward PowerShell commands.

## PowerShell Comment Standards to Follow

1. **Block Comment Header for Modules & Scripts**
    - Use PowerShell’s `[CmdletBinding()]` comment-based help at the top of each script or module:

```PowerShell
<#
.SYNOPSIS
  Queries domain controllers for replication status.

.DESCRIPTION
  Checks all DCs in the forest for replication health, outputs a sortable table,
  and emails alerts if any replication failures are found.

.PARAMETER Credential
  PSCredential object for domain access.

.PARAMETER Quiet
  Switch to suppress non-critical output.

.EXAMPLE
  .\Get-ADReplicationHealth.ps1 -Credential $adminCred -Quiet

.NOTES
  Requires ActiveDirectory module; tested on PowerShell 7.2.

.LINK
  https://docs.microsoft.com/powershell/module/activedirectory
#>
```

2. **Strategic Inline Comments**
    - _Complex Logic:_ e.g. filtering replication errors vs. warnings.
    - _Performance Decisions:_ e.g. using parallel jobs for querying multiple DCs.
    - _Security Considerations:_ e.g. why credential objects are scrubbed after use.
    - _Edge Cases:_ e.g. handling non-responsive domain controllers.
3. **What Not to Comment**
    - Simple variable assignments (e.g. `$DCs = Get-ADDomainController`).
    - Standard pipeline usage.
    - Self-explanatory loops or cmdlet calls.
4. Focus Areas
- _Active Directory Operations_
    - Comment on complex LDAP filters, replication queries, user/group provisioning logic.
- _Group Policy Management_
    - Explain script sequences for backing up/restoring GPOs, linking/unlinking, and policy versioning.
- _Network Services (DNS, DHCP)_
    - Document paging through large DNS zones, error-handling for stale DHCP leases, and performance tweaks.
- _Software Deployment & Patching_
    - Annotate logic for WSUS/API interactions, SCCM task sequence triggers, and rollback procedures.
- _Security & Auditing_
    - Clarify use of Windows Event logs, SIEM integration points, and secure credential handling.

## Comment Quality Guidelines

✅ **DO**
- Use full sentences in block help.
- Explain business reasons for each automation step.
- Note assumptions (e.g. forest functional level).
- Insert TODOs sparingly for technical debt.

❌ **DON’T**
- Over-document every pipeline segment.
- State the obvious (e.g. “# get services”).
- Use vague comments (“# fix later”).

## Implementation Checklist

1. Scan each `.ps1` and module for advanced logic.
2. Add comment-based help to public functions and scripts.
3. Inline-comment non-trivial loops, filters, and error-handling.
4. Review existing comments: improve or remove as needed.
5. Ensure consistency across all scripts.
