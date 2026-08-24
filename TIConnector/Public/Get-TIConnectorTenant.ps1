<#
.SYNOPSIS
    Retrieves the tenant from a TI-Connector.

.DESCRIPTION
    Sends a request via REST API to query the tenant from the target TI-Connector.
    Enriches the returned object with ComputerName and Credential properties to 
    support pipeline processing for downstream cmdlets.

.PARAMETER ComputerName
    FQDN or IP address of the target connector.

.PARAMETER Credential
    PSCredential object containing connector access credentials.

.PARAMETER Tenant
    Name of the tenant with "*"-wildcard support.

.EXAMPLE
    Get-TIConnectorTenant -ComputerName "192.168.1.100" -Credential $cred

    Retrieves the tenant configuration from the specified connector.
#>
function Get-TIConnectorTenant {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [string] $ComputerName,
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [PSCredential] $Credential,
        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [Alias("mandantId")]
        [string] $Tenant
    )

    process {
        $tenants = Get-TIConnectorContext -ComputerName $ComputerName -Credential $Credential | Select-Object -ExpandProperty mandanten

        if (-not [string]::IsNullOrEmpty($Tenant)) {
            $tenants = $tenants | Where-Object { $_.mandantId -like $Tenant }
        }

        if ($null -ne $tenants) {
            $tenants | Add-Member -MemberType NoteProperty -Name "ComputerName" -Value $ComputerName -Force
            $tenants | Add-Member -MemberType NoteProperty -Name "Credential" -Value $Credential -Force

            return $tenants
        }
    }
}