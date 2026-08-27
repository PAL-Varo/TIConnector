<#
.SYNOPSIS
    Retrieves the current logging settings of a TI-Connector.

.DESCRIPTION
    Queries the connector logging configuration via the REST API. The returned
    object is enriched with ComputerName and Credential properties so it can be
    passed to Set-TIConnectorLogSetting through the pipeline.

.PARAMETER ComputerName
    FQDN or IP address of the target connector.

.PARAMETER Credential
    PSCredential object containing connector access credentials.

.EXAMPLE
    Get-TIConnectorLogSetting -ComputerName "192.168.1.100" -Credential $cred

    Retrieves the current logging settings from the specified connector.

.EXAMPLE
    Get-TIConnectorLogSetting -ComputerName "192.168.1.100" -Credential $cred |
        Set-TIConnectorLogSetting -LogDays 30

    Retrieves the current settings, changes the retention period for module
    logs to 30 days, and sends the updated configuration to the connector.
#>
function Get-TIConnectorLogSetting {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [string] $ComputerName,
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [PSCredential] $Credential
    )

    process {
        $settings = Invoke-TIConnectorRequest -ComputerName $ComputerName -Credential $Credential -Request GetConnectorLogSetting

        if ($settings) {
            $settings | Add-Member -MemberType NoteProperty -Name "ComputerName" -Value $ComputerName -Force
            $settings | Add-Member -MemberType NoteProperty -Name "Credential" -Value $Credential -Force
            return $settings
        }
    }
}