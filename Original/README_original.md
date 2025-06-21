# Network Administration Script (Original)

A comprehensive, monolithic PowerShell script for managing Active Directory environments and network administration tasks. This is the original version of the NetworkAdmin tool before modularization.

## 📄 About This Version

This is the **original monolithic version** (network.ps1) that contains all functionality in a single 2,024-line PowerShell script. While this version is fully functional and feature-complete, it has been superseded by the modular NetworkAdmin PowerShell module for better maintainability and reusability.

> **Note**: For new implementations, consider using the modular version located in the parent directory. This original version is preserved for reference and legacy compatibility.

## 🚀 Features

### Core Functionality
- **User Management** - Search, list, and audit Active Directory users with advanced filtering
- **Computer Management** - Manage and monitor domain computers with connectivity testing
- **Group Management** - Handle AD groups and memberships with detailed analysis
- **Network Diagnostics** - Comprehensive network troubleshooting and connectivity testing
- **DNS Management** - DNS query, cache management, and server configuration
- **DHCP Information** - View DHCP configuration, lease information, and client details
- **Domain Controller Info** - Monitor DC status, health, and failover capabilities
- **Security & Audit** - Security compliance checks, privileged account auditing, and policy analysis
- **System Health Check** - Overall system health monitoring with performance metrics

### Advanced Features
- **Multi-Format Export** - Export results to CSV, JSON, or XML formats with automatic timestamping
- **Comprehensive Logging** - Complete audit trail with configurable retention policies
- **Input Validation** - Robust validation with configurable enforcement
- **Progress Indicators** - Visual feedback for long-running operations
- **Configuration Management** - External JSON configuration support via config.json
- **Credential Management** - Support for alternate credentials with secure handling
- **Built-in Help System** - Context-sensitive help accessible within the script
- **Retry Mechanisms** - Intelligent retry logic with exponential backoff for transient failures
- **Performance Optimization** - Paging support for large datasets, configurable timeouts, and caching
- **Customizable UI** - Configurable color schemes and display options
- **Object-Oriented Design** - PowerShell classes for better error handling and data management

## 📋 Requirements

### System Requirements
- **PowerShell 5.1** or later
- **Windows Server 2012 R2** or later / **Windows 10** or later
- **Active Directory PowerShell Module** (RSAT)

### Permissions
- Domain user account with appropriate permissions for the tasks you want to perform
- For security auditing features: Domain Admin or equivalent permissions recommended
- For DHCP information: Local administrator rights may be required

### Dependencies
- Remote Server Administration Tools (RSAT) for Active Directory module
- Network access to domain controllers
- Appropriate firewall rules for AD and network operations

## 🔧 Installation

1. **Download the script:**
   ```
   network.ps1
   ```

2. **Install Active Directory PowerShell Module:**
   ```powershell
   # On Windows 10/11
   Add-WindowsCapability -Online -Name Rsat.ActiveDirectory.DS-LDS.Tools~~~~0.0.1.0
   
   # On Windows Server
   Install-WindowsFeature -Name RSAT-AD-PowerShell
   ```

3. **Set execution policy (if needed):**
   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```

## 📖 Usage

### Basic Usage

```powershell
# Basic execution
.\network.ps1

# Specify domain
.\network.ps1 -Domain "company.local"

# Use alternate credentials
.\network.ps1 -Domain "company.local" -Credential (Get-Credential)

# Disable logging
.\network.ps1 -NoLog

# Custom log file location
.\network.ps1 -LogPath "C:\Logs\NetworkAdmin.txt"
```

### Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `-Domain` | String | No | Specify domain name (e.g., company.local) |
| `-Credential` | PSCredential | No | Use alternate credentials for AD operations |
| `-LogPath` | String | No | Custom path for log file (default: script directory) |
| `-NoLog` | Switch | No | Disable audit logging |

### Menu Navigation

- Use **number keys** to select menu options
- Use **B** to go back to previous menus
- Use **H** for help
- Use **Q** to quit the application

## 🎯 Menu Structure

```
MAIN MENU
├── 1. User Management
│   ├── 1. List all users
│   ├── 2. Search for specific user
│   ├── 3. Get user details
│   ├── 4. List disabled users
│   ├── 5. List users with password never expires
│   ├── 6. List users by group membership
│   └── 7. Check user last logon
├── 2. Computer Management
│   ├── 1. List all computers
│   ├── 2. Search for specific computer
│   ├── 3. Get computer details
│   ├── 4. List computers by OS
│   ├── 5. Test computer connectivity
│   └── 6. List inactive computers
├── 3. Group Management
│   ├── 1. List all groups
│   ├── 2. Search for specific group
│   ├── 3. Get group membership
│   ├── 4. List empty groups
│   └── 5. List groups by type
├── 4. Network Diagnostics
│   ├── 1. Ping test
│   ├── 2. Port connectivity test
│   ├── 3. DNS resolution test
│   ├── 4. Network adapter info
│   ├── 5. Route table
│   ├── 6. ARP table
│   └── 7. Network statistics
├── 5. DNS Management
│   ├── 1. DNS record lookup
│   ├── 2. DNS server configuration
│   ├── 3. Flush DNS cache
│   └── 4. DNS zone information
├── 6. DHCP Information
│   ├── 1. Current IP configuration
│   ├── 2. DHCP client info
│   └── 3. DHCP lease details
├── 7. Domain Controller Info
│   ├── 1. List domain controllers
│   ├── 2. DC health check
│   ├── 3. Domain functional level
│   └── 4. FSMO role holders
├── 8. Security & Audit
│   ├── 1. List privileged groups
│   ├── 2. Find admin accounts
│   ├── 3. Password policy info
│   ├── 4. Account lockout policy
│   └── 5. Check user privileges
├── 9. System Health Check
│   ├── 1. Disk space check
│   ├── 2. Memory usage
│   ├── 3. CPU utilization
│   ├── 4. Service status
│   └── 5. Event log errors
├── 10. Change Domain
├── H. Help
└── Q. Quit
```

## ⚙️ Configuration

The script supports an external `config.json` file (in parent directory) for customizing behavior:

```json
{
    "MaxRetries": 3,
    "TimeoutSeconds": 30,
    "DefaultDays": 30,
    "LogRetentionDays": 90,
    "PageSize": 1000,
    "LargeQueryThreshold": 5000,
    "NetworkTimeout": 10,
    "ADQueryTimeout": 60,
    "ExportFormats": ["CSV", "JSON", "XML"],
    "DefaultExportFormat": "CSV",
    "PingCount": 4,
    "EnableProgressBars": true,
    "ColorScheme": {
        "Success": "Green",
        "Warning": "Yellow", 
        "Error": "Red",
        "Info": "Cyan",
        "Header": "Cyan"
    },
    "Features": {
        "EnableExport": true,
        "EnableLogging": true,
        "EnableProgressBars": true,
        "EnableInputValidation": true,
        "EnableRetryMechanism": true,
        "EnableDetailedErrorMessages": true
    },
    "Performance": {
        "UseParallelProcessing": false,
        "MaxConcurrentOperations": 5,
        "CacheResults": true,
        "CacheExpirationMinutes": 15
    }
}
```

## 📁 File Structure

```
Original/
├── network.ps1               # This monolithic script (2,024 lines)
├── README_original.md        # This documentation
└── NetworkAdminLog.txt       # Audit log file (created automatically)
```

## 📊 Export Options

Results from queries can be exported in multiple formats:
- **CSV** - Excel-compatible format with proper delimiter handling
- **JSON** - Machine-readable format with hierarchical data preservation
- **XML** - Structured data format with schema validation

**Export Features:**
- Automatic timestamping of export files
- Configurable default export format
- Export path validation
- Large dataset handling
- Encoding support for international characters

## 📝 Logging and Auditing

The script maintains comprehensive audit logs including:
- **User actions and timestamps** - Who did what and when
- **Targets of operations** - What was accessed or modified
- **Results (success/failure)** - Operation outcomes
- **Error details** - Detailed error information for troubleshooting
- **Domain context** - Which domain was being administered
- **Retry attempts** - Failed operation retry details
- **Performance metrics** - Operation timing and efficiency data

## 🔍 Troubleshooting

### Common Issues

1. **"Unable to connect to domain"**
   - Verify domain name spelling and DNS resolution
   - Check network connectivity to domain controllers
   - Ensure appropriate firewall rules are in place
   - Validate credentials if using alternate authentication

2. **"Active Directory module not found"**
   - Install RSAT tools using the installation commands above
   - Import the ActiveDirectory module manually:
     ```powershell
     Import-Module ActiveDirectory
     ```
   - Verify module installation: `Get-Module -ListAvailable ActiveDirectory`

3. **"Access denied" errors**
   - Run with elevated privileges if needed
   - Use `-Credential` parameter for alternate credentials
   - Verify account permissions for the requested operation
   - Check domain trust relationships

4. **Export failures**
   - Check file system permissions for the export directory
   - Ensure sufficient disk space
   - Verify the script directory is writable
   - Check for file locks on existing export files

5. **Performance issues with large datasets**
   - Adjust `PageSize` and `LargeQueryThreshold` in config.json
   - Enable result caching for repeated queries
   - Use more specific search filters to reduce result sets
   - Consider running on domain controllers for better performance

6. **Timeout errors**
   - Increase `ADQueryTimeout` or `NetworkTimeout` in config.json
   - Check network latency to domain controllers
   - Verify domain controller performance and availability

## 🔒 Security Considerations

- **Credentials**: Never hardcode credentials in the script or configuration files
- **Logging**: Log files may contain sensitive information - secure appropriately with proper NTFS permissions
- **Permissions**: Follow principle of least privilege for operational accounts
- **Network**: Ensure secure network connections to domain controllers (use encrypted connections)
- **Configuration**: Protect config.json file with appropriate permissions
- **Export Data**: Secure exported files containing AD information
- **Audit Trail**: Regularly review audit logs for unauthorized access attempts

## 📚 Examples

### Example 1: Basic Domain Inventory
```powershell
.\network.ps1 -Domain "contoso.local"
# Select option 1 (User Management)
# Select option 1 (List all users)
# Choose Y to export results
```

### Example 2: Security Audit with Credentials
```powershell
$cred = Get-Credential
.\network.ps1 -Domain "contoso.local" -Credential $cred
# Select option 8 (Security & Audit)
# Select option 1 (List privileged groups)
```

### Example 3: Computer Health Check
```powershell
.\network.ps1 -Domain "contoso.local"
# Select option 2 (Computer Management)
# Select option 6 (List inactive computers)
# Enter 90 for 90-day threshold
# Export results for cleanup planning
```

## 🔄 Migration Path

This original script has been modernized into a modular PowerShell module. If you're currently using this version, consider migrating to the modular version for:

- **Better maintainability** - Organized into logical modules
- **Improved reusability** - Functions can be used independently
- **Enhanced testability** - Individual components can be unit tested
- **Future extensibility** - Easier to add new features

### How to Migrate

1. **Use the new entry point**: Replace `.\network.ps1` calls with `.\Start-NetworkAdminTool.ps1`
2. **Same parameters**: All command-line parameters remain identical
3. **Same functionality**: All features work exactly the same way
4. **Same configuration**: Uses the same config.json file

## 🔧 Technical Details

- **Total Lines**: 2,024 lines of PowerShell code
- **Architecture**: Monolithic (all functions in one file)
- **PowerShell Classes**: Uses modern PowerShell classes for error handling
- **Error Handling**: Comprehensive try/catch blocks with retry logic
- **Performance**: Optimized for large AD environments with paging and caching
- **Compatibility**: PowerShell 5.1+ on Windows Server 2012 R2+ or Windows 10+

## 📄 License

This script is provided as-is for educational and administrative purposes. Please review and test thoroughly before using in production environments.

## 📞 Support

For issues and questions:
1. Check the troubleshooting section above
2. Review PowerShell and Active Directory documentation
3. Test with minimal permissions to isolate permission issues
4. Check the audit logs for detailed error information
5. Review configuration settings for optimization opportunities

---

**Author:** System Administrator  
**Date:** June 2025  
**PowerShell Version:** 5.1+  
**Script Version:** 1.0 (Original Monolithic)  
**Script Size:** 2,024 lines  

> **Recommendation**: Consider migrating to the modular NetworkAdmin PowerShell module in the parent directory for improved maintainability and modern PowerShell practices.
    },
    "Features": {
        "EnableExport": true,
        "EnableLogging": true,
        "EnableProgressBars": true
    }
}
```

## 📦 Installation

1. **Copy the module files** to your PowerShell modules directory:
   ```powershell
   $modulePath = "$env:PSModulePath".Split(';')[0] + "\NetworkAdmin"
   Copy-Item -Path ".\NetworkAdmin" -Destination $modulePath -Recurse
   ```

2. **Or use it locally**:
   ```powershell
   Import-Module .\NetworkAdmin.psd1
   ```

## 🧪 Testing Individual Components

With the modular approach, you can test individual components:

```powershell
# Test only the AD operations
. .\Private\ADOperations.ps1
Test-ADQueryWithPaging -Filter "Name -like 'test*'"

# Test only network functions
. .\Private\NetworkOperations.ps1
Test-NetworkAdminConnectivity -Target "google.com" -Type "Ping"
```

## 🔍 Available Functions

### Public Functions (Exported)
- `Start-NetworkAdminTool` - Main interactive interface
- `Get-NetworkAdminConfig` - Get configuration settings
- `Set-NetworkAdminConfig` - Update configuration
- `Test-NetworkAdminConnectivity` - Test various connectivity types
- `Export-NetworkAdminResults` - Export data to various formats

### Private Functions (Internal)
- Configuration management functions
- Error handling utilities
- Network operation helpers
- AD query functions
- Caching mechanisms
- Logging utilities

## 💡 PowerShell Best Practices Implemented

1. **✅ Module Manifest** - Proper `.psd1` file with metadata
2. **✅ Function Organization** - Public/Private separation
3. **✅ Parameter Validation** - Input validation and type checking
4. **✅ Comment-Based Help** - Comprehensive help documentation
5. **✅ Error Handling** - Try/catch blocks and custom error handling
6. **✅ Verbose Logging** - Detailed logging with Write-Verbose
7. **✅ Pipeline Support** - Functions work with PowerShell pipeline
8. **✅ Aliases** - User-friendly aliases for common functions
9. **✅ Configuration Management** - External config file support
10. **✅ Version Control Friendly** - Smaller files, easier to track changes

## 🔄 Migration from Monolithic Script

To migrate from your existing script:

1. **Backup** your current script
2. **Install** the module
3. **Update** any scripts that call the old script to use the new module
4. **Configure** any custom settings in `config.json`
5. **Test** thoroughly in a non-production environment

## 📈 Performance Benefits

- **Faster Loading**: Only loads required functions
- **Memory Efficient**: Smaller memory footprint
- **Caching**: Built-in caching for expensive operations
- **Parallel Processing**: Support for concurrent operations where appropriate

## 🛠️ Development Guidelines

When adding new functionality:

1. **Public functions** go in `Public/` folder
2. **Internal helpers** go in `Private/` folder
3. **Classes** go in `Classes/` folder
4. **Update manifest** to export new public functions
5. **Add help documentation** with examples
6. **Include error handling** and logging
7. **Follow naming conventions** (Verb-NetworkAdminNoun)

## 📚 Further Reading

- [PowerShell Module Concepts](https://docs.microsoft.com/en-us/powershell/scripting/developer/module/understanding-a-windows-powershell-module)
- [Advanced Functions](https://docs.microsoft.com/en-us/powershell/scripting/learn/ps101/09-functions)
- [PowerShell Best Practices](https://github.com/PoshCode/PowerShellPracticeAndStyle)

This modular approach transforms your large script into a maintainable, professional PowerShell module that follows industry best practices!
