<#
.SYNOPSIS
    Retrieves cards from a TI-Connector.

.DESCRIPTION
    Queries cards from the TI-Connector REST API. 
    Supports retrieving all cards, filtering by one or more card handles.
    Fully supports pipeline binding via property names.

.PARAMETER ComputerName
    FQDN or IP address of the target connector.

.PARAMETER Credential
    PSCredential object containing connector access credentials.

.PARAMETER CardHandle
    One or more card card handles to query specifically.

.EXAMPLE
    Get-TIConnectorCard -ComputerName "192.168.1.100" -Credential $cred
    Retrieves all cards connected to the specified connector.

.EXAMPLE
    Get-TIConnectorCard -ComputerName "192.168.1.100" -Credential $cred -CardHandle "SMC-KT-4"
    Retrieves specific card details by its handle.
#>
function Get-TIConnectorCard {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [string]$ComputerName,
        [Parameter(Mandatory = $true, Position = 1, ValueFromPipelineByPropertyName = $true)]
        [PSCredential]$Credential,
        [Parameter(Position = 2, ValueFromPipelineByPropertyName = $true)]
        [string[]]$CardHandle
    )

    process {
        $cards = if ($CardHandle) {
            foreach ($handle in $CardHandle) {
                Invoke-TIConnectorRequest -ComputerName $ComputerName -Credential $Credential -Request GetConnectorCard -PathParameters @{ CardHandle = $handle }
            }
        }
        else {
            Invoke-TIConnectorRequest -ComputerName $ComputerName -Credential $Credential -Request GetConnectorCards
        }

        # Decorate each card object with formatted time and connection context
        foreach ($card in $cards) {
            $card | Add-Member -MemberType NoteProperty -Name "expirationDateTime" -Value ([DateTimeOffset]::FromUnixTimeMilliseconds($card.expirationDate).ToLocalTime().DateTime) -Force
            $card | Add-Member -MemberType NoteProperty -Name "ComputerName" -Value $ComputerName -Force
            $card | Add-Member -MemberType NoteProperty -Name "Credential" -Value $Credential -Force
        }

        return $cards
    }
}