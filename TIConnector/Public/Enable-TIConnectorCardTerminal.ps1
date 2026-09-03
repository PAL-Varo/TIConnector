<#
.SYNOPSIS
    Enables one or more card terminals on a TI-Connector.

.DESCRIPTION
    Sends an enable request for the specified card terminal(s) via REST API.
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
    Enable-TIConnectorCardTerminal -ComputerName "192.168.1.100" -Credential $cred -Id "373a533e-77eb-45a3-87ad-435a6b6826ad"

.EXAMPLE
    Get-TIConnectorCardTerminal -ComputerName "192.168.1.100" -Credential $cred -Name "KT" | Enable-TIConnectorCardTerminal
#>
function Enable-TIConnectorCardTerminal {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [string] $ComputerName,
        [Parameter(Mandatory = $true, Position = 1, ValueFromPipelineByPropertyName = $true)]
        [PSCredential] $Credential,
        [Parameter(Position = 2, ValueFromPipelineByPropertyName = $true)]
        [Alias("CardTerminalId", "ctId")]
        [string[]] $Id,
        [Parameter(Position = 3, ValueFromPipelineByPropertyName = $true)]
        [Alias("CardTerminalName", "Label")]
        [string[]] $Name
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

        if (-not $Id -and $Name) {
            $resolved = Get-TIConnectorCardTerminal -ComputerName $ComputerName -Credential $Credential -Name $Name
            $Id = $resolved.cardTerminalID
            $Name = $resolved.label
        }

        for ($i = 0; $i -lt $Id.Count; $i++) {
            $currentId = $Id[$i]
            $currentName = if ($Name -and $i -lt $Name.Count) { $Name[$i] } else { $null }

            $targetName = if ($currentName) { "$currentName ($currentId)" } else { $currentId }

            if ($PSCmdlet.ShouldProcess($targetName, "Enable card terminal")) {
                try {
                    Invoke-TIConnectorRequest -ComputerName $ComputerName -Credential $Credential -Request EnableConnectorCardTerminal -PathParameters @{ CardTerminalID = $currentId } | Out-Null
                    Write-Verbose "Card terminal '$targetName' successfully enabled."
                }
                catch {
                    $PSCmdlet.WriteError($_)
                }
            }
        }
    }
}