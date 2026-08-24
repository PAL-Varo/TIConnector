<#
.SYNOPSIS
    Retrieves the client system from a TI-Connector.

.DESCRIPTION
    Sends a request via REST API to query the client system from the target TI-Connector.
    Enriches the returned object with ComputerName and Credential properties to 
    support pipeline processing for downstream cmdlets.

.PARAMETER ComputerName
    FQDN or IP address of the target connector.

.PARAMETER Credential
    PSCredential object containing connector access credentials.

.PARAMETER ClientSystem
    Name of the client system with "*"-wildcard support.

.EXAMPLE
    Get-TIConnectorClientSystem -ComputerName "192.168.1.100" -Credential $cred

    Retrieves the client system configuration from the specified connector.
#>
function Get-TIConnectorClientSystem {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [string] $ComputerName,
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [PSCredential] $Credential,
        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [Alias("clientSystemId")]
        [string] $ClientSystem
    )

    process {
        $clientSystems = Get-TIConnectorContext -ComputerName $ComputerName -Credential $Credential | Select-Object -ExpandProperty clientSystems

        if (-not [string]::IsNullOrEmpty($ClientSystem)) {
            $clientSystems = $clientSystems | Where-Object { $_.clientSystemId -like $ClientSystem }
        }

        if ($clientSystems) {
            $clientSystems | Add-Member -MemberType NoteProperty -Name "ComputerName" -Value $ComputerName -Force
            $clientSystems | Add-Member -MemberType NoteProperty -Name "Credential" -Value $Credential -Force

            return $clientSystems
        }
    }
}