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

    try {
        $sdsUrl = "http://$ComputerName/connector.sds"
        Write-Verbose "Fetching product information from $sdsUrl"
        
        $response = Invoke-RestMethod -Uri $sdsUrl -Method Get -TimeoutSec 5 -ErrorAction Stop
        [xml]$sdsXml = $response

        $vendorNode = $sdsXml.SelectSingleNode("//*[local-name()='ProductVendorID']")
        
        if (-not $vendorNode -or [string]::IsNullOrWhitespace($vendorNode.InnerText)) {
            throw "ProductVendorID missing or empty in connector.sds response from $ComputerName."
        }

        $vendor = $vendorNode.InnerText.Trim().ToUpper()

        $script:TIConnectorVendorCache[$key] = $vendor
        
        return $vendor
    }
    catch {
        $PSCmdlet.WriteError((New-Object System.Management.Automation.ErrorRecord(
            [System.Exception]::new("Failed to determine connector vendor for '$ComputerName' via connector.sds: $_"),
            "VendorResolutionFailed",
            [System.Management.Automation.ErrorCategory]::ResourceUnavailable,
            $ComputerName
        )))
        return $null
    }
}