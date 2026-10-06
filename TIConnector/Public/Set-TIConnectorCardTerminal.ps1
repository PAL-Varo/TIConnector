<#
.SYNOPSIS
    Sets card terminal settings on a TI-Connector.

.DESCRIPTION
    Set card terminal settings via the TI-Connector REST API using a Read-Modify-Write pattern. 
    Fully supports pipeline binding via property names.

.PARAMETER ComputerName
    FQDN or IP address of the target connector.

.PARAMETER Credential
    PSCredential object containing connector access credentials.

.PARAMETER Id
    One or more card terminal IDs (UUIDs) to target.
    Aliases: CardTerminalId, ctId.

.PARAMETER Name
    One or more card terminal labels/names to target.
    Aliases: CardTerminalName, Label.

.PARAMETER AdminUsername
    Username of the card terminal admin account.

.PARAMETER AdminPassword
    Password of the card terminal admin account as a secure string.

.PARAMETER NewName
    Set a new name/label for the card terminal.
    Can only be used when targeting a single card terminal.

.PARAMETER ValidateAdminSession
    Validates the admin credentials on the card terminal.

.EXAMPLE
    Get-TIConnectorCardTerminal -ComputerName "192.168.1.100" -Credential $cred -Name "KT-Empfang" | Set-TIConnectorCardTerminal -AdminUsername "admin" -AdminPassword $secPassword
    Updates admin credentials for a specific card terminal piped from Get-TIConnectorCardTerminal.

.EXAMPLE
    Set-TIConnectorCardTerminal -ComputerName "192.168.1.100" -Credential $cred -Id "373a533e-77eb-45a3-87ad-435a6b6826ad" -NewName "KT-Sprechzimmer1"
    Renames a specific card terminal by ID.
#>
function Set-TIConnectorCardTerminal {
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
        [string[]] $Name,
        [Parameter()]
        [string] $AdminUsername,
        [Parameter()]
        [securestring] $AdminPassword,
        [Parameter()]
        [string] $NewName,
        [Parameter()]
        [switch] $ValidateAdminSession,
        [Parameter()]
        [switch] $PassThru
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
        
        if (-not $cardTerminals) {
            Write-Verbose "No card terminals found matching criteria on '$ComputerName'."
            return
        }

        if ($PSBoundParameters.ContainsKey('NewName') -and @($cardTerminals).Count -gt 1) {
            $PSCmdlet.ThrowTerminatingError(
                [System.Management.Automation.ErrorRecord]::new(
                    [System.InvalidOperationException]::new("Cannot apply 'NewName' when multiple card terminals are targeted."),
                    "MultipleTerminalsNewNameNotSupported",
                    [System.Management.Automation.ErrorCategory]::InvalidArgument,
                    $cardTerminals
                )
            )
        }

        foreach ($terminal in $cardTerminals) {
            $terminalId = if ($terminal.cardTerminalID) { $terminal.cardTerminalID } else { $terminal.id }
            $targetName = "$($terminal.label) ($terminalId)"

            $payload = [PSCustomObject]@{
                adminUsername        = $terminal.adminUsername
                adminPassword        = $terminal.adminPassword
                autoUpdate           = $terminal.autoUpdate
                label                = $terminal.label
                validateAdminSession = $ValidateAdminSession.IsPresent
            }

            if ($PSBoundParameters.ContainsKey('AdminUsername')) {
                $payload.adminUsername = $AdminUsername
            }
            
            if ($PSBoundParameters.ContainsKey('AdminPassword')) {
                $payload.adminPassword = [System.Net.NetworkCredential]::new('', $AdminPassword).Password
            }
            
            if ($PSBoundParameters.ContainsKey('NewName')) {
                $payload.label = $NewName
            }

            $jsonBody = $payload | ConvertTo-Json -Depth 10

            if ($PSCmdlet.ShouldProcess($targetName, "Set card terminal settings on '$ComputerName'")) {
                try {
                    $response = Invoke-TIConnectorRequest -ComputerName $ComputerName -Credential $Credential `
                        -Request SetConnectorCardTerminal `
                        -PathParameters @{ CardTerminalID = $terminalId } `
                        -Body $jsonBody

                    if ($ValidateAdminSession) {
                        Write-Verbose "Admin session validation succeeded. Reconnecting card terminal '$targetName'..."
                        Enable-TIConnectorCardTerminal -ComputerName $ComputerName -Credential $Credential -Id $terminalId -Confirm:$false
                    }

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
}