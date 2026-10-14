<#
.SYNOPSIS
    Retrieves the current vpn settings of a TI-Connector.

.DESCRIPTION
    Queries the connector vpn configuration via the REST API. The returned
    object is enriched with ComputerName and Credential properties so it can be
    passed to Set-TIConnectorVPNSetting through the pipeline.

.PARAMETER ComputerName
    FQDN or IP address of the target connector.

.PARAMETER Credential
    PSCredential object containing connector access credentials.

.EXAMPLE
    Get-TIConnectorVPNSetting -ComputerName "192.168.1.100" -Credential $cred

    Retrieves the current vpn settings from the specified connector.
#>
function Get-TIConnectorVPNSetting {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [string] $ComputerName,
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [PSCredential] $Credential
    )

    process {
        $settings = Invoke-TIConnectorRequest -ComputerName $ComputerName -Credential $Credential -Request GetConnectorVPNSetting

        if ($settings) {
            $settings | Add-Member -MemberType NoteProperty -Name "ComputerName" -Value $ComputerName -Force
            $settings | Add-Member -MemberType NoteProperty -Name "Credential" -Value $Credential -Force
            return $settings
        }
    }
}