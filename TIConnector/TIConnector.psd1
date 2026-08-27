#
# Module manifest for module 'TIConnector'
#
@{

# Script module or binary module file associated with this manifest.
RootModule = 'TIConnector.psm1'

# Version number of this module.
ModuleVersion = '1.3.1'

# Supported PSEditions
CompatiblePSEditions = @('Core')

# ID used to uniquely identify this module
GUID = 'e4f61575-3375-4d97-8194-dc59900e0a0d'

# Author of this module
Author = 'Patrick Lehmann'

# Company or vendor of this module
CompanyName = 'Community'

# Copyright statement for this module
Copyright = '(c) 2026 Patrick Lehmann. All rights reserved.'

# Description of the functionality provided by this module
Description = 'PowerShell module to manage TI Connectors via REST API.'

# Minimum version of the PowerShell engine required by this module
PowerShellVersion = '7.0'

# Functions to export from this module, for best performance, do not use wildcards and do not list private functions.
FunctionsToExport = @(
    'Test-TIConnectorAuthentication',
    'Get-TIConnectorStatus',
    'Wait-TIConnectorOnline',
    'Restart-TIConnector',
    'Get-TIConnectorCardTerminal',
    'Enable-TIConnectorCardTerminal',
    'Disable-TIConnectorCardTerminal',
    'Connect-TIConnectorCardTerminal',
    'Remove-TIConnectorCardTerminalAssignment',
    'Remove-TIConnectorCardTerminal',
    'Get-TIConnectorContext',
    'Get-TIConnectorWorkplace',
    'Get-TIConnectorTenant',
    'Get-TIConnectorInvocationContext',
    'Get-TIConnectorClientSystem',
    'Export-TIConnectorContext',
    'ConvertTo-TIConnectorContextCsv',
    'Get-TIConnectorCard',
    'Get-TIConnectorLogSetting',
    'Set-TIConnectorLogSetting'
)

# Cmdlets to export from this module
CmdletsToExport = @()

# Variables to export from this module
VariablesToExport = @()

# Aliases to export from this module
AliasesToExport = @()

# Private data to pass to the module specified in RootModule
PrivateData = @{
    PSData = @{
        # Tags applied to this module. These help with module discovery in online galleries.
        Tags = @('TI', 'Telematikinfrastruktur', 'Connector', 'Konnektor', 'CardTerminal', 'REST')

        # A URL to the license for this module.
        LicenseUri = 'https://github.com/PAL-Varo/TIConnector/blob/main/LICENSE'

        # A URL to the main project website for this project.
        ProjectUri = 'https://github.com/PAL-Varo'

        # ReleaseNotes of this module
        ReleaseNotes = 'Initial release.'
    }
}

}
