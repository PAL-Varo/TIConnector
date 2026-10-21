<#
.SYNOPSIS
    Retrieves firmware update information for all card terminal groups connected to a TI-Connector.

.DESCRIPTION
    Queries the terminal groups from the connector and fetches specific update information 
    for each hardware/firmware combination.

.PARAMETER ComputerName
    FQDN or IP address of the target connector.

.PARAMETER Credential
    PSCredential object containing connector access credentials.

.EXAMPLE
    Get-TIConnectorCardTerminalUpdate -ComputerName "192.168.1.100" -Credential $cred
#>
function Get-TIConnectorCardTerminalUpdate {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [string] $ComputerName,
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [PSCredential] $Credential
    )

    process {
        $terminalGroups = Invoke-TIConnectorRequest -ComputerName $ComputerName -Credential $Credential -Request GetConnectorTerminalGroups

        if (-not $terminalGroups) {
            Write-Verbose "No terminal groups found on '$ComputerName'."
            return
        }

        $allUpdates = foreach ($group in $terminalGroups) {
            if ($group.productVendorId -and $group.productCode -and $group.hwVersion -and $group.fwVersion) {
                $pathParams = @{
                    Vendor    = $group.productVendorId
                    Product   = $group.productCode
                    HwVersion = $group.hwVersion
                    FwVersion = $group.fwVersion
                }

                $updateInfo = Invoke-TIConnectorRequest -ComputerName $ComputerName -Credential $Credential `
                    -Request GetConnectorTerminalUpdateInformation `
                    -PathParameters $pathParams

                if ($updateInfo) {
                    [PSCustomObject]@{
                        ProductVendorId        = $group.productVendorId
                        ProductCode            = $group.productCode
                        HardwareVersion        = $group.hwVersion
                        CurrentFirmwareVersion = $group.fwVersion
                        AssignedTerminals      = $group.terminals
                        UpdateInformation      = $updateInfo
                        ComputerName           = $ComputerName
                        Credential             = $Credential
                    }
                }
            }
        }

        return $allUpdates
    }
}