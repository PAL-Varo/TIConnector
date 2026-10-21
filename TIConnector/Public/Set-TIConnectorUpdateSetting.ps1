<#
.SYNOPSIS
    Updates the update settings of a TI-Connector.

.DESCRIPTION
    Reads the current update configuration, applies the specified changes,
    and sends the complete updated configuration to the connector via the REST
    API. When an object from Get-TIConnectorUpdateSetting is piped in, that object
    is used as the configuration instead of querying it again.

.PARAMETER ComputerName
    FQDN or IP address of the target connector.

.PARAMETER Credential
    PSCredential object containing connector access credentials.

.PARAMETER InputObject
    Update configuration object, typically received from Get-TIConnectorUpdateSetting 
    through the pipeline.

.PARAMETER AutoUpdateCheck
    Enables or disables automatic update checks.

.PARAMETER AutoUpdateDownload
    Enables or disables automatic update downloads.

.PARAMETER AutoUpdate
    Enables or disables automatic updates.

.PARAMETER AutoUpdateWeekDay
    Day of the week for automatic updates. Valid values include MONDAY, EVERY_DAY, etc.

.PARAMETER AutoUpdateTimeHour
    Hour of the day (0-23) for automatic updates.

.PARAMETER AutoUpdateTimeMinute
    Minute of the hour (0-59) for automatic updates.

.PARAMETER SupportTrialUpdates
    Enables or disables support for trial updates.

.PARAMETER AutoUpdateWave
    Update wave. Valid values are typically EARLY, LATE, etc.

.PARAMETER AutoActivateInventoryNetworks
    Enables or disables automatic activation of inventory networks.

.PARAMETER AutoUpdateConnectorDependsOnFinishedTerminalUpdates
    Controls whether connector updates depend on finished terminal updates.

.PARAMETER PassThru
    Returns the updated configuration object from the connector.

.EXAMPLE
    Get-TIConnectorUpdateSetting -ComputerName "192.168.1.100" -Credential $cred |
        Set-TIConnectorUpdateSetting -AutoUpdate $true -AutoUpdateWeekDay "EVERY_DAY" -AutoUpdateTimeHour 15 -PassThru
#>
function Set-TIConnectorUpdateSetting {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High', DefaultParameterSetName = 'Direct')]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [string] $ComputerName,
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [PSCredential] $Credential,
        [Parameter(ValueFromPipeline = $true, ParameterSetName = 'Pipeline')]
        [psobject] $InputObject,
        [Parameter()]
        [bool] $AutoUpdateCheck,
        [Parameter()]
        [bool] $AutoUpdateDownload,
        [Parameter()]
        [bool] $AutoUpdate,
        [Parameter()]
        [ValidateSet('EVERY_DAY', 'MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY', 'SATURDAY', 'SUNDAY')]
        [string] $AutoUpdateWeekDay,
        [Parameter()]
        [int] $AutoUpdateTimeHour,
        [Parameter()]
        [int] $AutoUpdateTimeMinute,
        [Parameter()]
        [bool] $SupportTrialUpdates,
        [Parameter()]
        [ValidateSet('EARLY', 'LATE')]
        [string] $AutoUpdateWave,
        [Parameter()]
        [bool] $AutoActivateInventoryNetworks,
        [Parameter()]
        [bool] $AutoUpdateConnectorDependsOnFinishedTerminalUpdates,
        [Parameter()]
        [switch] $PassThru
    )

    process {
        $payload = if ($InputObject) {
            $InputObject.psobject.Copy()
        }
        else {
            Get-TIConnectorUpdateSetting -ComputerName $ComputerName -Credential $Credential
        }

        if (-not $payload) { 
            Write-Verbose "No update settings retrieved from '$ComputerName'."
            return 
        }

        if ($PSBoundParameters.ContainsKey('AutoUpdateCheck')) {
            $payload.autoUpdateCheck = $AutoUpdateCheck
        }
        if ($PSBoundParameters.ContainsKey('AutoUpdateDownload')) {
            $payload.autoUpdateDownload = $AutoUpdateDownload
        }
        if ($PSBoundParameters.ContainsKey('AutoUpdate')) {
            $payload.autoUpdate = $AutoUpdate
        }
        if ($PSBoundParameters.ContainsKey('AutoUpdateWeekDay')) {
            $payload.autoUpdateWeekDay = $AutoUpdateWeekDay
        }
        if ($PSBoundParameters.ContainsKey('AutoUpdateTimeHour')) {
            $payload.autoUpdateTimeHour = $AutoUpdateTimeHour
        }
        if ($PSBoundParameters.ContainsKey('AutoUpdateTimeMinute')) {
            $payload.autoUpdateTimeMinute = $AutoUpdateTimeMinute
        }
        if ($PSBoundParameters.ContainsKey('SupportTrialUpdates')) {
            $payload.supportTrialUpdates = $SupportTrialUpdates
        }
        if ($PSBoundParameters.ContainsKey('AutoUpdateWave')) {
            $payload.autoUpdateWave = $AutoUpdateWave
        }
        if ($PSBoundParameters.ContainsKey('AutoActivateInventoryNetworks')) {
            $payload.autoActivateInventoryNetworks = $AutoActivateInventoryNetworks
        }
        if ($PSBoundParameters.ContainsKey('AutoUpdateConnectorDependsOnFinishedTerminalUpdates')) {
            $payload.autoUpdateConnectorDependsOnFinishedTerminalUpdates = $AutoUpdateConnectorDependsOnFinishedTerminalUpdates
        }

        if ($payload.PSObject.Properties['ComputerName']) { $payload.PSObject.Properties.Remove('ComputerName') }
        if ($payload.PSObject.Properties['Credential']) { $payload.PSObject.Properties.Remove('Credential') }

        $jsonBody = $payload | ConvertTo-Json -Depth 10

        if ($PSCmdlet.ShouldProcess($ComputerName, "Set update settings")) {
            try {
                $response = Invoke-TIConnectorRequest -ComputerName $ComputerName -Credential $Credential `
                    -Request SetConnectorUpdateSetting `
                    -Body $jsonBody

                if ($PassThru) {
                    if ($response.PSObject.Properties['data']) {
                        return $response.data
                    }
                    return $response
                }
            }
            catch {
                $PSCmdlet.WriteError($_)
            }
        }
    }
}