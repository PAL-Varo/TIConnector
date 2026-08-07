<#
.SYNOPSIS
    Resolves the vendor of a target TI-Connector.

.DESCRIPTION
    Determines the vendor ID (e.g., SECUN, KOCOC) of a given TI-Connector by fetching its 
    connector.sds manifest over HTTP. If HTTP access is unreachable or hardened/disabled, 
    it falls back to a TCP port heuristic probe against known vendor ports configured 
    in $script:ConnectorRequests.
    
    Resolved vendors are stored in memory ($script:TIConnectorVendorCache) to prevent 
    redundant network lookups on subsequent execution.

.PARAMETER ComputerName
    FQDN or IP address of the target TI-Connector. Supports pipeline input.

.EXAMPLE
    Get-TIConnectorVendor -ComputerName "192.168.1.100"

    Resolves and returns the vendor string for the connector at 192.168.1.100.
#>
function Get-TIConnectorVendor {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]$ComputerName
    )

    $key = $ComputerName.ToLower()

    if ($script:TIConnectorVendorCache.ContainsKey($key)) {
        return $script:TIConnectorVendorCache[$key]
    }

    $vendor = $null

    # Step 1: Attempt vendor detection via connector.sds (HTTP)
    try {
        $sdsUrl = "http://$ComputerName/connector.sds"
        Write-Verbose "Fetching product information from $sdsUrl"
        
        $response = Invoke-RestMethod -Uri $sdsUrl -Method Get -TimeoutSec 3 -ErrorAction Stop
        [xml]$sdsXml = $response

        $vendorNode = $sdsXml.SelectSingleNode("//*[local-name()='ProductVendorID']")
        
        if ($vendorNode -and -not [string]::IsNullOrWhitespace($vendorNode.InnerText)) {
            $vendor = $vendorNode.InnerText.Trim().ToUpper()
            Write-Verbose "Resolved vendor '$vendor' via connector.sds for '$ComputerName'."
        }
    }
    catch {
        Write-Verbose "Failed to fetch connector.sds via HTTP from '$ComputerName': $_"
    }

    # Step 2: Fallback to TCP port heuristic if SDS retrieval failed
    if (-not $vendor) {
        Write-Verbose "Attempting vendor detection via TCP port heuristics for '$ComputerName'..."

        # Lightweight .NET TCP socket test helper
        $testPort = {
            param([string]$Target, [int]$Port, [int]$TimeoutMs = 1000)
            $client = [System.Net.Sockets.TcpClient]::new()
            try {
                $async = $client.BeginConnect($Target, $Port, $null, $null)
                if ($async.AsyncWaitHandle.WaitOne($TimeoutMs, $false)) {
                    $client.EndConnect($async)
                    $client.Close()
                    return $true
                }
                $client.Close()
                return $false
            }
            catch {
                return $false
            }
        }

        # Check configured vendor ports in $script:ConnectorRequests
        foreach ($vendorKey in $script:ConnectorRequests.Keys) {
            $configuredPort = $script:ConnectorRequests[$vendorKey].Port
            if ($configuredPort -and (& $testPort -Target $ComputerName -Port $configuredPort)) {
                $vendor = $vendorKey
                Write-Verbose "Detected vendor '$vendor' via open port $configuredPort on '$ComputerName'."
                break
            }
        }
    }

    # Step 3: Cache result or write error record
    if ($vendor) {
        $script:TIConnectorVendorCache[$key] = $vendor
        return $vendor
    }

    $PSCmdlet.WriteError((New-Object System.Management.Automation.ErrorRecord(
        [System.Exception]::new("Failed to determine connector vendor for '$ComputerName' (connector.sds unreachable and port probes failed)."),
        "VendorResolutionFailed",
        [System.Management.Automation.ErrorCategory]::ResourceUnavailable,
        $ComputerName
    )))

    return $null
}