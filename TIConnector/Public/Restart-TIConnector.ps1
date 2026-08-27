<#
.SYNOPSIS
    Restarts a TI-Connector.

.DESCRIPTION
    Sends a restart request to the specified connector via REST API. 
    Supports -WhatIf and -Confirm safety prompts. Optionally waits for the 
    connector to complete the reboot and come back online.

.PARAMETER ComputerName
    FQDN or IP address of the target connector.

.PARAMETER Credential
    PSCredential object containing connector access credentials.

.PARAMETER Wait
    If specified, blocks execution until the connector has completed rebooting 
    and is fully reachable again.

.PARAMETER TimeoutSeconds
    Maximum time in seconds to wait when -Wait is used. Defaults to 600 (10 minutes).

.EXAMPLE
    Restart-TIConnector -ComputerName "192.168.1.100" -Credential $cred -Wait
#>
function Restart-TIConnector {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [string] $ComputerName,
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [PSCredential] $Credential,
        [switch] $Wait,
        [int] $TimeoutSeconds = 600
    )

    process {
        if ($PSCmdlet.ShouldProcess($ComputerName, "Restart TI-Connector")) {
            Write-Verbose "Triggering restart on connector '$ComputerName'..."

            $vendor = Get-TIConnectorVendor -ComputerName $ComputerName
            $port = $script:ConnectorRequests[$vendor].Port

            Write-Verbose $vendor
            Write-Verbose $port
            
            Invoke-TIConnectorRequest -ComputerName $ComputerName -Credential $Credential -Request RestartConnector | Out-Null

            if ($Wait) {
                Write-Verbose "Waiting for connector '$ComputerName' to complete restart..."
                Wait-TIConnectorOnline -ComputerName $ComputerName -RestartTriggered -TimeoutSeconds $TimeoutSeconds -Port $port
            }
        }
    }
}