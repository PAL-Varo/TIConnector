<#
.SYNOPSIS
    Internal helper to execute REST API requests against the TI-Connector.

.DESCRIPTION
    Executes HTTP/REST calls against configured connector endpoints, handles URI parameter 
    replacement, bearer token acquisition, authorization headers, and response parsing.

.PARAMETER ComputerName
    FQDN or IP address of the target connector.

.PARAMETER Credential
    PSCredential object containing the user credentials used to request an authentication token.

.PARAMETER Request
    The operation key defined in $script:ConnectorRequests.

.PARAMETER PathParameters
    Hashtable containing URI placeholders and their runtime values.
#>
function Invoke-TIConnectorRequest {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string] $ComputerName,
        [Parameter(Mandatory = $true)]
        [PSCredential] $Credential,
        [Parameter(Mandatory = $true)]
        [ValidateSet("RemoveConnectorSession",
            "GetConnectorStatus",
            "RestartConnector",
            "GetConnectorCardTerminal",
            "GetConnectorCardTerminals",
            "EnableConnectorCardTerminal",
            "EnableConnectorCardTerminalConnection",
            "DisableConnectorCardTerminal",
            "RemoveConnectorCardTerminalAssignment",
            "RemoveConnectorCardTerminal",
            "GetConnectorContext")]
        [string] $Request,
        [hashtable] $PathParameters = @{}
    )

    $Token = Get-ConnectorToken -ComputerName $ComputerName -Credential $Credential

    operation = $script:ConnectorRequests.Secunet.Operations[$Request]
    $path = $operation.Path

    foreach ($parameter in $PathParameters.GetEnumerator()) {
        $path = $path.Replace("{$($parameter.Key)}", [uri]::EscapeDataString([string]$parameter.Value))
    }

    $url = "https://{0}:{1}/{2}" -f $ComputerName, $script:ConnectorRequests.Secunet.Port, $path
    $method = $operation.Method
    $expectedStatusCode = $operation.ExpectedStatusCode

    $headers = @{
        "Authorization" = "Bearer $Token"
    }

    try {
        $response = Invoke-WebRequest `
            -Uri $url `
            -Method $method `
            -Headers $headers `
            -ContentType "application/json" `
            -SkipCertificateCheck `
            -ErrorAction Stop
            
        if ($response.StatusCode -notin $expectedStatusCode) {
            throw "Unexpected status code: $($response.StatusCode)"
        }
        
        if ([string]::IsNullOrWhiteSpace($response.Content)) {
            return $null
        }
        return $response.Content | ConvertFrom-Json -Depth 10
    }
    catch {
        throw "Connector request failed: $($_.Exception.Message)"
    }
}
