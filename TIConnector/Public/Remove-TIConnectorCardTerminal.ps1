<#
.SYNOPSIS
    Removes one or more card terminals on a TI-Connector.

.DESCRIPTION
    Sends a remove request for the specified card terminal(s) via REST API.
    Supports -WhatIf and -Confirm safety prompts and pipeline binding.

.PARAMETER ComputerName
    FQDN or IP address of the target connector.

.PARAMETER Credential
    PSCredential object containing connector access credentials.

.PARAMETER Id
    One or more card terminal IDs (UUIDs).
    Aliases: CardTerminalId, ctId.

.PARAMETER Name
    One or more card terminal labels/names. If specified without -Id, 
    the IDs will be dynamically resolved.
    Aliases: CardTerminalName, Label.

.EXAMPLE
    Remove-TIConnectorCardTerminal -ComputerName "192.168.1.100" -Credential $cred -Id "373a533e-77eb-45a3-87ad-435a6b6826ad"

.EXAMPLE
    Get-TIConnectorCardTerminal -ComputerName "192.168.1.100" -Credential $cred -Name "KT" | Remove-TIConnectorCardTerminal
#>
function Remove-TIConnectorCardTerminal {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
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
        [string[]]$Name,
        [Parameter(ValueFromPipelineByPropertyName)]
        [string[]]$Connected,
        [Parameter(ValueFromPipelineByPropertyName)]
        [string[]]$Correlation
    )

    process {
        if (-not $Id -and -not $Name) {
            $PSCmdlet.WriteError((New-Object System.Management.Automation.ErrorRecord(
                        [System.ArgumentException]::new("You must specify either -Id or -Name."),
                        "MissingIdentifier",
                        [System.Management.Automation.ErrorCategory]::InvalidArgument,
                        $null
                    )))
            return
        }

        if (-not $Correlation -or (-not $Id -and $Name)) {
            $queryParams = @{
                ComputerName = $ComputerName
                Credential   = $Credential
            }
            if ($Id) { $queryParams['Id'] = $Id }
            elseif ($Name) { $queryParams['Name'] = $Name }

            $resolved = Get-TIConnectorCardTerminal @queryParams

            $Id = $resolved.cardTerminalID
            $Name = $resolved.label
            $Connected = $resolved.connected
            $Correlation = $resolved.correlation
        }

        for ($i = 0; $i -lt $Id.Count; $i++) {
            $currentId = $Id[$i]
            $currentName = if ($Name -and $i -lt $Name.Count) { $Name[$i] } else { $null }
            $currentCorrelation = if ($Correlation -and $i -lt $Correlation.Count) { $Correlation[$i] } else { $null }

            $targetName = if ($currentName) { "$currentName ($currentId)" } else { $currentId }

            if ($PSCmdlet.ShouldProcess($targetName, "Remove card terminal")) {
                try {
                    if ($currentCorrelation -eq "AKTIV") {
                        Disable-TIConnectorCardTerminal -ComputerName $ComputerName -Credential $Credential -Id $currentId -Confirm:$false | Out-Null
                    }
                    
                    if ($currentCorrelation -in "AKTIV", "ZUGEWIESEN") {
                        Remove-TIConnectorCardTerminalAssignment -ComputerName $ComputerName -Credential $Credential -Id $currentId -Confirm:$false | Out-Null
                    }
                    
                    Invoke-TIConnectorRequest -ComputerName $ComputerName -Credential $Credential -Request RemoveConnectorCardTerminal -PathParameters @{ CardTerminalID = $currentId } | Out-Null
                    Write-Verbose "Card terminal '$targetName' successfully removed."
                }
                catch {
                    $PSCmdlet.WriteError($_)
                }
            }
        }
    }
}