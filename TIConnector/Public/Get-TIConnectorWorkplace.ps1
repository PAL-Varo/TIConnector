<#
.SYNOPSIS
    Retrieves the workplace from a TI-Connector.

.DESCRIPTION
    Sends a request via REST API to query the workplace from the target TI-Connector.
    Enriches the returned object with ComputerName and Credential properties to 
    support pipeline processing for downstream cmdlets.

.PARAMETER ComputerName
    FQDN or IP address of the target connector.

.PARAMETER Credential
    PSCredential object containing connector access credentials.

.PARAMETER Workplace
    Name of the workplace with "*"-wildcard support.

.PARAMETER Expand
    Resolve card terminal names.

.EXAMPLE
    Get-TIConnectorWorkplace -ComputerName "192.168.1.100" -Credential $cred

    Retrieves the workplace configuration from the specified connector.
#>
function Get-TIConnectorWorkplace {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [string] $ComputerName,
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [PSCredential] $Credential,
        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [Alias("arbeitsplatzId")]
        [string] $Workplace,
        [switch] $Expand
    )

    process {
        $workplaces = Get-TIConnectorContext -ComputerName $ComputerName -Credential $Credential | Select-Object -ExpandProperty arbeitsplaetze

        if (-not [string]::IsNullOrEmpty($Workplace)) {
            $workplaces = $workplaces | Where-Object { $_.arbeitsplatzId -like $Workplace }
        }

        if (-not $workplaces) {
            return
        }

        $allCTs = $null
        if ($Expand) {
            $allCTs = Get-TIConnectorCardTerminal -ComputerName $ComputerName -Credential $Credential
        }

        foreach ($wp in $workplaces) {
            $localCTs = $wp.localCardTerminalInternalIds
            $remoteCTs = $wp.remoteCardTerminalInternalIds
            $cts = @($localCTs) + @($remoteCTs)

            $wp | Add-Member -MemberType NoteProperty -Name "cardTerminalId" -Value $cts -Force

            if ($Expand) {
                $localCTNames = @()
                $remoteCTNames = @()

                if ($localCTs) {
                    $localCTNames = ($allCTs | Where-Object { $localCTs -contains $_.internalId }).label
                    $wp | Add-Member -MemberType NoteProperty -Name "localCardTerminalInternalNames" -Value $localCTNames -Force
                }
                if ($remoteCTs) {
                    $remoteCTNames = ($allCTs | Where-Object { $remoteCTs -contains $_.internalId }).label
                    $wp | Add-Member -MemberType NoteProperty -Name "remoteCardTerminalInternalNames" -Value $remoteCTNames -Force
                }

                $ctNames = @($localCTNames) + @($remoteCTNames)

                $wp | Add-Member -MemberType NoteProperty -Name "cardTerminalNames" -Value $ctNames -Force
            }

            $wp | Add-Member -MemberType NoteProperty -Name "ComputerName" -Value $ComputerName -Force
            $wp | Add-Member -MemberType NoteProperty -Name "Credential" -Value $Credential -Force
        }
        
        return $workplaces
    }
}