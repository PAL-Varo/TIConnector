<#
.SYNOPSIS
    Retrieves the invocation context from a TI-Connector.

.DESCRIPTION
    Sends a request via REST API to query the invocation context from the target TI-Connector.
    Enriches the returned object with ComputerName and Credential properties to 
    support pipeline processing for downstream cmdlets.

.PARAMETER ComputerName
    FQDN or IP address of the target connector.

.PARAMETER Credential
    PSCredential object containing connector access credentials.

.EXAMPLE
    Get-TIConnectorInvocationContext -ComputerName "192.168.1.100" -Credential $cred

    Retrieves the invocation context configuration from the specified connector.
#>
function Get-TIConnectorInvocationContext {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [string] $ComputerName,
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [PSCredential] $Credential
    )

    process {
        $invocationContext = Get-TIConnectorContext -ComputerName $ComputerName -Credential $Credential | Select-Object -ExpandProperty aufrufkontexte 

        if ($null -ne $invocationContext) {
            $invocationContext | Add-Member -MemberType NoteProperty -Name "ComputerName" -Value $ComputerName -Force
            $invocationContext | Add-Member -MemberType NoteProperty -Name "Credential" -Value $Credential -Force

            return $invocationContext
        }
    }
}