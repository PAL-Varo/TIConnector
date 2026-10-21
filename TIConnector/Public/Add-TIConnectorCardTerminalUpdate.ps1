<#
.SYNOPSIS
    Manually registers or uploads a card terminal firmware update on a TI-Connector.

.DESCRIPTION
    Sends a manual firmware update definition for a specific card terminal group
    to the connector via the REST API. Supports pipeline input from Get-TIConnectorCardTerminalUpdate
    or automatic single-group detection.

.PARAMETER ComputerName
    FQDN or IP address of the target connector.

.PARAMETER Credential
    PSCredential object containing connector access credentials.

.PARAMETER InputObject
    Card terminal update object received from Get-TIConnectorCardTerminalUpdate through the pipeline.

.PARAMETER Vendor
    Product vendor ID of the card terminal group (e.g., DECHY).

.PARAMETER Product
    Product code of the card terminal group (e.g., ST1506).

.PARAMETER HwVersion
    Hardware version of the card terminal group.

.PARAMETER CurrentFwVersion
    Current base firmware version of the card terminal group.

.PARAMETER TargetFwVersion
    The new target firmware version being registered (in the payload).

.PARAMETER Phase
    Update phase (default: OPB).

.PARAMETER Priority
    Firmware priority. Valid values are LOW, NORMAL, HIGH, CRITICAL (default: NORMAL).

.PARAMETER ReleaseNotes
    Release notes describing the manual update.

.PARAMETER PassThru
    Returns the response from the connector.

.EXAMPLE
    Get-TIConnectorCardTerminalUpdate -ComputerName "192.168.1.100" -Credential $cred |
        Add-TIConnectorCardTerminalUpdate -TargetFwVersion "5.0.0" -ReleaseNotes "Manuelles Update auf 5.0.0" -PassThru
#>
function Add-TIConnectorCardTerminalUpdate {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High', DefaultParameterSetName = 'Direct')]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [string] $ComputerName,

        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [PSCredential] $Credential,

        [Parameter(ValueFromPipeline = $true, ParameterSetName = 'Pipeline')]
        [psobject] $InputObject,

        [Parameter(ParameterSetName = 'Direct')]
        [string] $Vendor,

        [Parameter(ParameterSetName = 'Direct')]
        [string] $Product,

        [Parameter(ParameterSetName = 'Direct')]
        [string] $HwVersion,

        [Parameter(ParameterSetName = 'Direct')]
        [string] $CurrentFwVersion,

        [Parameter(Mandatory = $true)]
        [string] $TargetFwVersion,

        [Parameter()]
        [string] $Phase = 'OPB',

        [Parameter()]
        [ValidateSet('NORMAL', 'CRITICAL')]
        [string] $Priority = 'NORMAL',

        [Parameter()]
        [string] $ReleaseNotes,

        [Parameter()]
        [switch] $PassThru
    )

    process {
        $targetVendor = if ($InputObject) { $InputObject.ProductVendorId } else { $Vendor }
        $targetProduct = if ($InputObject) { $InputObject.ProductCode } else { $Product }
        $targetHw = if ($InputObject) { $InputObject.HardwareVersion } else { $HwVersion }
        $targetCurrentFw = if ($InputObject) { $InputObject.CurrentFirmwareVersion } else { $CurrentFwVersion }

        if (-not ($targetVendor -and $targetProduct -and $targetHw -and $targetCurrentFw)) {
            Write-Verbose "Terminal group identifiers not fully provided. Querying terminal groups on '$ComputerName'..."
            $terminalGroups = Invoke-TIConnectorRequest -ComputerName $ComputerName -Credential $Credential -Request GetConnectorTerminalGroups

            if (-not $terminalGroups) {
                $PSCmdlet.ThrowTerminatingError(
                    [System.Management.Automation.ErrorRecord]::new(
                        [System.InvalidOperationException]::new("No terminal groups found on '$ComputerName' to auto-detect target parameters."),
                        "NoTerminalGroupsFound",
                        [System.Management.Automation.ErrorCategory]::ObjectNotFound,
                        $ComputerName
                    )
                )
            }

            if (@($terminalGroups).Count -eq 1) {
                $targetVendor = $terminalGroups[0].productVendorId
                $targetProduct = $terminalGroups[0].productCode
                $targetHw = $terminalGroups[0].hwVersion
                $targetCurrentFw = $terminalGroups[0].fwVersion
                Write-Verbose "Auto-selected single terminal group: $targetVendor / $targetProduct / $targetHw / $targetCurrentFw"
            }
            else {
                $PSCmdlet.ThrowTerminatingError(
                    [System.Management.Automation.ErrorRecord]::new(
                        [System.InvalidOperationException]::new("Multiple terminal groups found on '$ComputerName'. Please specify Vendor, Product, HwVersion, and CurrentFwVersion, or pipe an object from Get-TIConnectorCardTerminalUpdate."),
                        "MultipleTerminalGroupsAmbiguous",
                        [System.Management.Automation.ErrorCategory]::InvalidArgument,
                        $terminalGroups
                    )
                )
            }
        }

        $payload = [PSCustomObject]@{
            productVendorId      = $null
            productCode          = $null
            hwVersion            = $null
            fwVersion            = $TargetFwVersion
            phase                = $Phase
            fmPriority           = $Priority
            firmwareReleaseNotes = $ReleaseNotes
        }

        $jsonBody = $payload | ConvertTo-Json -Depth 10
        $pathParams = @{
            Vendor    = $targetVendor
            Product   = $targetProduct
            HwVersion = $targetHw
            FwVersion = $targetCurrentFw
        }

        $targetName = "Card terminal update for '$targetVendor/$targetProduct' ($targetHw -> $TargetFwVersion)"

        if ($PSCmdlet.ShouldProcess($targetName, "Add card terminal update")) {
            try {
                $response = Invoke-TIConnectorRequest -ComputerName $ComputerName -Credential $Credential `
                    -Request AddConnectorTerminalUpdate `
                    -PathParameters $pathParams `
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