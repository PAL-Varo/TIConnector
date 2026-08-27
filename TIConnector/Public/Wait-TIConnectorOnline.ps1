<#
.SYNOPSIS
    Waits for a TI-Connector to become available via Ping and TCP Port.

.DESCRIPTION
    Monitors the network state of a connector. Can optionally wait for an initial 
    shutdown (if a restart was just triggered), followed by ICMP response and TCP port availability.

.PARAMETER ComputerName
    FQDN or IP address of the target connector.

.PARAMETER Port
    TCP Port to check for web service availability. Defaults to the configured Secunet port (8500).

.PARAMETER RestartTriggered
    If set, waits for the connector to go offline first before waiting for it to come back online.

.PARAMETER TimeoutSeconds
    Maximum time in seconds to wait before throwing a timeout error. Default is 600 (10 minutes).

.EXAMPLE
    Wait-TIConnectorOnline -ComputerName "192.168.1.100" -RestartTriggered
#>
function Wait-TIConnectorOnline {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [string] $ComputerName,
        [Parameter(Mandatory = $true)]
        [int] $Port,
        [switch] $RestartTriggered,
        [int] $TimeoutSeconds = 600
    )

    process {
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

        if ($RestartTriggered) {
            Write-Verbose "Waiting for connector '$ComputerName' to shut down..."

            while (Test-Connection $ComputerName -Count 1 -Quiet) {
                if ($stopwatch.Elapsed.TotalSeconds -ge $TimeoutSeconds) {
                    throw "Timed out waiting for connector '$ComputerName' to shut down after $TimeoutSeconds seconds."
                }

                Write-Progress -Activity "Waiting for connector restart ($ComputerName)" -Status "Waiting for shutdown" -PercentComplete -1
                Start-Sleep -Seconds 1
            }

            Write-Verbose "Connector '$ComputerName' is offline."
        }

        Write-Verbose "Waiting for connector '$ComputerName' to respond to ping..."
        while (-not (Test-Connection -ComputerName $ComputerName -Count 1 -Quiet)) {
            if ($stopwatch.Elapsed.TotalSeconds -ge $TimeoutSeconds) {
                throw "Timed out waiting for connector '$ComputerName' ICMP response after $TimeoutSeconds seconds."
            }

            Write-Progress -Activity "Waiting for connector $ComputerName to restart" -Status "Waiting for ping response" -PercentComplete -1
            Start-Sleep -Seconds 1
        }

        Write-Verbose "Connector '$ComputerName' responds to ping."
        Write-Verbose "Waiting for connector '$ComputerName' web service (TCP $Port)..."

        do {
            if ($stopwatch.Elapsed.TotalSeconds -ge $TimeoutSeconds) {
                throw "Timed out waiting for connector '$ComputerName' web service on port $Port after $TimeoutSeconds seconds."
            }

            Write-Progress -Activity "Waiting for connector '$ComputerName' to restart" -Status "Waiting for web service (TCP $Port)" -PercentComplete -1

            $ready = Test-NetConnection -ComputerName $ComputerName -Port $Port -InformationLevel Quiet -WarningAction SilentlyContinue

            if (-not $ready) {
                Start-Sleep -Seconds 2
            }
        } until ($ready)

        Write-Progress -Activity "Waiting for connector '$ComputerName' to restart" -Completed
        Write-Verbose "Connector '$ComputerName' is online."
    }
}