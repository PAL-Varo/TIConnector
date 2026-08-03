<#
.SYNOPSIS
    Retrieves the current status of the TI-Connector.

.DESCRIPTION
    Queries the connector status endpoint and converts Unix millisecond 
    timestamps into local DateTime objects.

.PARAMETER ComputerName
    FQDN or IP address of the target connector.

.PARAMETER Credential
    PSCredential object containing connector access credentials.

.EXAMPLE
    Get-TIConnectorStatus -ComputerName "192.168.1.100" -Credential $cred
#>
function Get-TIConnectorStatus {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [string] $ComputerName,
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [PSCredential] $Credential
    )

    process {
        $status = Invoke-TIConnectorRequest -ComputerName $ComputerName -Credential $Credential -Request GetConnectorStatus

        $operatingStates = if ($status.operatingStates) {
            $status.operatingStates | Where-Object { $_.value -eq $true } | ForEach-Object {
                [PSCustomObject]@{
                    MainCondition = $_.mainCondition
                    Severity      = $_.severity
                    ErrorType     = $_.errorType
                    Value         = $_.value
                    ValidFrom     = if ($_.validFrom) { [DateTimeOffset]::FromUnixTimeMilliseconds($_.validFrom).ToLocalTime().DateTime } else { $null }
                    Parameters    = $_.parameters
                }
            }
        }
        else { @() }

        return [PSCustomObject]@{
            ComputerName              = $ComputerName
            ConnectorStarted          = if ($status.connectorStarted) { [DateTimeOffset]::FromUnixTimeMilliseconds($status.connectorStarted).ToLocalTime().DateTime } else { $null }
            VpnTiConnected            = $status.vpnTiConnected
            VpnTiConnectionStateDate  = if ($status.vpnTiConnectionStateDate) { [DateTimeOffset]::FromUnixTimeMilliseconds($status.vpnTiConnectionStateDate).ToLocalTime().DateTime } else { $null }
            VpnSisConnected           = $status.vpnSisConnected
            VpnSisConnectionStateDate = if ($status.vpnSisConnectionStateDate) { [DateTimeOffset]::FromUnixTimeMilliseconds($status.vpnSisConnectionStateDate).ToLocalTime().DateTime } else { $null }
            RestartRequired           = $status.restartRequired
            OperatingStates           = $operatingStates
        }
    }
}