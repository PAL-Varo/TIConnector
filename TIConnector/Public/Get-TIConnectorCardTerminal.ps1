<#
.SYNOPSIS
    Retrieves card terminals from a TI-Connector.

.DESCRIPTION
    Queries card terminals from the TI-Connector REST API. 
    Supports retrieving all terminals, filtering by one or more CardTerminalIds, 
    or filtering by Name/Label. Fully supports pipeline binding via property names.

.PARAMETER ComputerName
    FQDN or IP address of the target connector.

.PARAMETER Credential
    PSCredential object containing connector access credentials.

.PARAMETER Id
    One or more card terminal IDs (UUIDs) to query specifically.
    Aliases: CardTerminalId, ctId.

.PARAMETER Name
    One or more card terminal labels/names to filter for.
    Aliases: CardTerminalName, Label.

.EXAMPLE
    Get-TIConnectorCardTerminal -ComputerName "192.168.1.100" -Credential $cred
    Retrieves all card terminals connected to the specified connector.

.EXAMPLE
    Get-TIConnectorCardTerminal -ComputerName "192.168.1.100" -Credential $cred -CardTerminalId "373a533e-77eb-45a3-87ad-435a6b6826ad"
    Retrieves specific card terminal details by its ID.
#>
function Get-TIConnectorCardTerminal {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [string]$ComputerName,
        [Parameter(Mandatory = $true, Position = 1, ValueFromPipelineByPropertyName = $true)]
        [PSCredential]$Credential,
        [Parameter(Position = 2, ValueFromPipelineByPropertyName = $true)]
        [Alias("CardTerminalId", "ctId")]
        [string[]]$Id,
        [Parameter(Position = 3, ValueFromPipelineByPropertyName = $true)]
        [Alias("CardTerminalName", "Label")]
        [string[]]$Name
    )

    process {
        $cardTerminals = if ($Id) {
            foreach ($id in $Id) {
                Invoke-TIConnectorRequest -ComputerName $ComputerName -Credential $Credential -Request GetConnectorCardTerminal -PathParameters @{ CardTerminalID = $id }
            }
        }
        elseif ($Name) {
            $allTerminals = Invoke-TIConnectorRequest -ComputerName $ComputerName -Credential $Credential -Request GetConnectorCardTerminals
            $allTerminals | Where-Object { $Name -contains $_.label }
        }
        else {
            Invoke-TIConnectorRequest -ComputerName $ComputerName -Credential $Credential -Request GetConnectorCardTerminals
        }

        # Decorate each terminal object with connection context
        foreach ($terminal in $cardTerminals) {
            $terminal | Add-Member -MemberType NoteProperty -Name "ComputerName" -Value $ComputerName -Force
            $terminal | Add-Member -MemberType NoteProperty -Name "Credential" -Value $Credential -Force
        }

        return $cardTerminals
    }
}