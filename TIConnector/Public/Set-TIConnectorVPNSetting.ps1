<#
.SYNOPSIS
    Updates the VPN settings of a TI-Connector.

.DESCRIPTION
    Reads the current VPN configuration, applies the specified changes (such as 
    transport IP addresses or the DNSSEC trust anchor), and sends the complete 
    updated configuration to the connector via the REST API. When an object 
    from Get-TIConnectorVPNSetting is piped in, that object is used as the 
    configuration instead of querying it again.

.PARAMETER ComputerName
    FQDN or IP address of the target connector.

.PARAMETER Credential
    PSCredential object containing connector access credentials.

.PARAMETER InputObject
    VPN configuration object, typically received from Get-TIConnectorVPNSetting 
    through the pipeline.

.PARAMETER TransportIpAddress
    Array of IP addresses for the servers transport configuration.

.PARAMETER DNSDomain
    DNS domain of the access service for the VPN connection.

.PARAMETER TrustAnchor
    Raw XML string containing the DNSSEC trust anchor definition.

.PARAMETER TrustAnchorPath
    Path to an XML file containing the DNSSEC trust anchor definition.
    Alias: Path

.PARAMETER PassThru
    Returns the updated configuration object from the connector.

.EXAMPLE
    Set-TIConnectorVPNSetting -ComputerName "192.168.1.100" -Credential $cred `
        -TransportIpAddress "185.91.107.68", "146.185.102.25"

    Updates the servers transport IP addresses.

.EXAMPLE
    Get-TIConnectorVPNSetting -ComputerName "192.168.1.100" -Credential $cred |
        Set-TIConnectorVPNSetting -TrustAnchorPath "C:\configs\root-anchors.xml" -PassThru

    Uses the configuration received from the pipeline, updates the trust anchor 
    from a file, and returns the updated object.
#>
function Set-TIConnectorVPNSetting {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High', DefaultParameterSetName = 'Direct')]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [string] $ComputerName,
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [PSCredential] $Credential,
        [Parameter(ValueFromPipeline = $true, ParameterSetName = 'Pipeline')]
        [psobject] $InputObject,
        [string[]] $TransportIpAddress,
        [Parameter()]
        [string] $DNSDomain,
        [Parameter()]
        [string] $TrustAnchor,
        [Parameter()]
        [Alias("Path")]
        [string] $TrustAnchorPath,
        [Parameter()]
        [switch] $PassThru
    )

    process {
        $payload = if ($InputObject) {
            $InputObject.psobject.Copy()
        }
        else {
            Get-TIConnectorVPNSetting -ComputerName $ComputerName -Credential $Credential
        }

        if (-not $payload) { 
            Write-Verbose "No VPN settings retrieved from '$ComputerName'."
            return 
        }

        if ($PSBoundParameters.ContainsKey('TransportIpAddress')) {
            if (-not $payload.serversTransport) {
                $payload | Add-Member -NotePropertyName 'serversTransport' -NotePropertyValue ([PSCustomObject]@{}) -Force
            }
            $payload.serversTransport.ipAdresses = @($TransportIpAddress)
        }

        if ($PSBoundParameters.ContainsKey('DNSDomain')) {
            $payload.domainVPNAccessInt = $DNSDomain
        }

        if ($PSBoundParameters.ContainsKey('TrustAnchorPath')) {
            if (-not (Test-Path -Path $TrustAnchorPath)) {
                $PSCmdlet.ThrowTerminatingError(
                    [System.Management.Automation.ErrorRecord]::new(
                        [System.IO.FileNotFoundException]::new("Trust anchor file not found at '$TrustAnchorPath'."),
                        "TrustAnchorFileNotFound",
                        [System.Management.Automation.ErrorCategory]::ObjectNotFound,
                        $TrustAnchorPath
                    )
                )
            }
            $xmlContent = Get-Content -Path $TrustAnchorPath -Raw -Encoding utf8
            $payload.dnsSecTrustAnchor = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($xmlContent))
        }
        elseif ($PSBoundParameters.ContainsKey('TrustAnchor')) {
            $payload.dnsSecTrustAnchor = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($TrustAnchor))
        }

        if ($payload.PSObject.Properties['ComputerName']) { $payload.PSObject.Properties.Remove('ComputerName') }
        if ($payload.PSObject.Properties['Credential']) { $payload.PSObject.Properties.Remove('Credential') }

        $jsonBody = $payload | ConvertTo-Json -Depth 10

        if ($PSCmdlet.ShouldProcess($ComputerName, "Set VPN settings")) {
            try {
                $response = Invoke-TIConnectorRequest -ComputerName $ComputerName -Credential $Credential `
                    -Request SetConnectorVPNSetting `
                    -Body $jsonBody

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