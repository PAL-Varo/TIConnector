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

    $token = Get-TIConnectorToken -ComputerName $ComputerName -Credential $Credential

    $operation = $script:ConnectorRequests.Secunet.Operations[$Request]
    $path = $operation.Path

    foreach ($parameter in $PathParameters.GetEnumerator()) {
        $path = $path.Replace("{$($parameter.Key)}", [uri]::EscapeDataString([string]$parameter.Value))
    }

    $url = "https://{0}:{1}/{2}" -f $ComputerName, $script:ConnectorRequests.Secunet.Port, $path

    $headers = @{
        "Authorization" = "Bearer $token"
    }

    $response = Invoke-TIConnectorHttp `
        -Uri $url  `
        -Method $operation.Method  `
        -Headers $headers  `
        -ExpectedStatusCode $operation.ExpectedStatusCode

    if ([string]::IsNullOrWhiteSpace($response.Content)) {
        return $null
    }
    return $response.Content | ConvertFrom-Json -Depth 10
}