<#
.SYNOPSIS
    Exports the TI-Connector context configuration to a JSON file.

.DESCRIPTION
    Retrieves the context settings from a TI-Connector using Get-TIConnectorContext and exports 
    the configuration data as a formatted JSON file. Automatically strips internal wrapper properties 
    (such as credentials) prior to export.

.PARAMETER ComputerName
    FQDN or IP address of the target connector.

.PARAMETER Credential
    PSCredential object containing connector access credentials.

.PARAMETER Path
    The file path where the JSON configuration should be saved.

.EXAMPLE
    Export-TIConnectorContext -ComputerName "192.168.1.100" -Credential $cred -Path "C:\Exports\Context.json"

    Exports the connector context configuration to the specified JSON file.
#>
function Export-TIConnectorContext {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [string] $ComputerName,
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [PSCredential] $Credential,
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [string] $Path
    )

    process {
        $connectorContext = Get-TIConnectorContext -ComputerName $ComputerName -Credential $Credential

        if ($null -ne $connectorContext) {
            $exportObject = $connectorContext.PSObject.Copy()
            $exportObject.PSObject.Properties.Remove('ComputerName')

            $exportObject | ConvertTo-Json -Depth 10 | Set-Content -Path $Path -Encoding utf8BOM
            Write-Verbose "Successfully exported connector context for '$ComputerName' to '$Path'."
        }
    }
}