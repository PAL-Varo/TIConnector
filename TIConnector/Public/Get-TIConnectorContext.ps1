<#
.SYNOPSIS
    Retrieves the current context configuration from a TI-Connector.

.DESCRIPTION
    Sends a request via REST API to query the context settings (e.g., mandant, client system, workplace assignments) 
    from the target TI-Connector. Enriches the returned object with ComputerName and Credential properties to 
    support pipeline processing for downstream cmdlets.

.PARAMETER ComputerName
    FQDN or IP address of the target connector.

.PARAMETER Credential
    PSCredential object containing connector access credentials.

.EXAMPLE
    Get-TIConnectorContext -ComputerName "192.168.1.100" -Credential $cred

    Retrieves the context configuration from the specified connector.
#>
function Get-TIConnectorContext {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [string] $ComputerName,
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [PSCredential] $Credential
    )

    process {
        $connectorContext = Invoke-TIConnectorRequest -ComputerName $ComputerName -Credential $Credential -Request GetConnectorContext

        if ($null -ne $connectorContext) {
            $connectorContext | Add-Member -MemberType NoteProperty -Name "ComputerName" -Value $ComputerName -Force
            $connectorContext | Add-Member -MemberType NoteProperty -Name "Credential" -Value $Credential -Force

            return $connectorContext
        }
    }
}