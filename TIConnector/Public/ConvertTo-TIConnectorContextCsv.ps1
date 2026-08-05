<#
.SYNOPSIS
    Flattens a TI-Connector context structure into relational records.

.DESCRIPTION
    Resolves workplace and card terminal internal IDs within the connector context 
    and returns a flat array of PSCustomObjects suitable for table views or CSV export.

.PARAMETER Context
    The TIConnector.Context object returned by Get-TIConnectorContext or parsed from JSON.

.EXAMPLE
    Get-TIConnectorContext -ComputerName "192.168.1.100" -Credential $cred | ConvertTo-TIConnectorContextCsv | Export-Csv -Path "Context.csv" -Delimiter ";" -NoTypeInformation
#>
function ConvertTo-TIConnectorContextCsv {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [psobject]$Context
    )

    process {
        $computerName = $Context.ComputerName

        $cardTerminalLookup = @{}
        foreach ($terminal in $Context.kartenTerminals) {
            if ($terminal.internalId) {
                $cardTerminalLookup[$terminal.internalId] = $terminal
            }
        }

        $workplaceLookup = @{}
        foreach ($workplace in $Context.arbeitsplaetze) {
            if ($workplace.internalId) {
                $workplaceLookup[$workplace.internalId] = $workplace
            }
        }

        $resolveTerminals = {
            param($terminalIds, $lookup)
            if (-not $terminalIds) { return $null }
            $resolved = foreach ($id in $terminalIds) {
                if ($lookup.ContainsKey($id)) {
                    $item = $lookup[$id]
                    if ($item.label) { "$($item.label) ($id)" } else { $id }
                }
                else {
                    $id
                }
            }
            return ($resolved -join ", ")
        }

        foreach ($callContext in $Context.aufrufkontexte) {
            $workplace = $workplaceLookup[$callContext.arbeitsplatzInternalId]

            [PSCustomObject]@{
                WorkplaceId         = $callContext.arbeitsplatzId
                ClientSystemId      = $callContext.clientSystemId
                MandantId           = $callContext.mandantId
                LocalCardTerminals  = & $resolveTerminals $workplace.localCardTerminalInternalIds $cardTerminalLookup
                RemoteCardTerminals = & $resolveTerminals $workplace.remoteCardTerminalInternalIds $cardTerminalLookup
                ComputerName        = $computerName
            }
        }
    }
}