<#
.SYNOPSIS
    Updates the logging settings of a TI-Connector.

.DESCRIPTION
    Reads the current logging configuration, applies the specified changes,
    and sends the complete updated configuration to the connector via the REST
    API. When an object from Get-TIConnectorLogSetting is piped in, that object
    is used as the configuration instead of querying it again.

.PARAMETER ComputerName
    FQDN or IP address of the target connector.

.PARAMETER Credential
    PSCredential object containing connector access credentials.

.PARAMETER InputObject
    Logging configuration object, typically received from
    Get-TIConnectorLogSetting through the pipeline.

.PARAMETER LogDays
    Number of days for which module logs are retained.

.PARAMETER SecurityLogDays
    Number of days for which security logs are retained.

.PARAMETER Severity
    Minimum severity for module log entries. Valid values are INFO, WARNING,
    ERROR, DEBUG and FATAL.

.PARAMETER LogSuccessfulCryptoOps
    Controls whether successful cryptographic operations are logged. Valid
    values are ENABLED and DISABLED.

.EXAMPLE
    Set-TIConnectorLogSetting -ComputerName "192.168.1.100" -Credential $cred `
        -LogDays 30 -SecurityLogDays 90 -Severity WARNING `
        -LogSuccessfulCryptoOps DISABLED

    Updates the retention periods, log severity and logging of
    successful cryptographic operations.

.EXAMPLE
    Get-TIConnectorLogSetting -ComputerName "192.168.1.100" -Credential $cred |
        Set-TIConnectorLogSetting -LogDays 30 -Severity DEBUG

    Uses the configuration received from the pipeline and changes the module
    log retention period and severity.
#>
function Set-TIConnectorLogSetting {
    [CmdletBinding(DefaultParameterSetName = 'Direct')]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [string] $ComputerName,
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [PSCredential] $Credential,
        [Parameter(ValueFromPipeline = $true, ParameterSetName = 'Pipeline')]
        [psobject] $InputObject,
        [Parameter()]
        [int] $LogDays,
        [Parameter()]
        [int] $SecurityLogDays,
        [Parameter()]
        [ValidateSet('INFO', 'WARNING', 'ERROR', 'DEBUG', 'FATAL')]
        [string] $Severity,
        [Parameter()]
        [ValidateSet('ENABLED', 'DISABLED')]
        [string] $LogSuccessfulCryptoOps
    )

    process {
        $payload = if ($InputObject) {
            $InputObject.psobject.Copy()
        }
        else {
            Get-TIConnectorLogSetting -ComputerName $ComputerName -Credential $Credential
        }

        if (-not $payload) { return }

        if ($PSBoundParameters.ContainsKey('SecurityLogDays')) {
            $payload.securityLogDays = [string]$SecurityLogDays
        }

        if ($PSBoundParameters.ContainsKey('LogSuccessfulCryptoOps')) {
            $payload.logSuccessfulCryptoOps = $LogSuccessfulCryptoOps
        }

        if ($PSBoundParameters.ContainsKey('LogDays') -or $PSBoundParameters.ContainsKey('Severity')) {
            foreach ($module in $payload.logInfo) {
                if ($PSBoundParameters.ContainsKey('LogDays')) {
                    $module.logDays = [string]$LogDays
                }
                if ($PSBoundParameters.ContainsKey('Severity')) {
                    $module.severity = $Severity
                }
            }
        }

        $payload.PSObject.Properties.Remove('ComputerName')
        $payload.PSObject.Properties.Remove('Credential')

        $jsonBody = $payload | ConvertTo-Json -Depth 10

        Invoke-TIConnectorRequest -ComputerName $ComputerName -Credential $Credential -Request SetConnectorLogSetting -Body $jsonBody
    }
}