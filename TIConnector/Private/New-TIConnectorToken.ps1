<#
.SYNOPSIS
    Requests a new authentication token from a TI-Connector.

.DESCRIPTION
    Sends the supplied credentials to the TI-Connector login endpoint and
    extracts the bearer token from the Authorization response header. The
    token is returned as a string for use in authenticated REST API requests.

    This function is an internal helper and is not exported by the
    TIConnector module. The credential password is sent to the connector over
    HTTPS. The connector must be trusted because its certificate validation is
    handled by the underlying HTTP helper.

.PARAMETER ComputerName
    The FQDN or IP address of the target TI-Connector. The connector listens
    on the module's configured management port.

.PARAMETER Credential
    A PSCredential object containing the username and password used to
    authenticate against the connector.

.OUTPUTS
    System.String

    The bearer token returned by the connector.

.EXAMPLE
    $credential = Get-Credential
    $token = New-TIConnectorToken -ComputerName 'connector.example' -Credential $credential

    Requests a new bearer token using credentials entered by the user.

.NOTES
    The function throws an exception when the login request fails, the
    connector does not return an Authorization header, or no bearer token can
    be extracted from that header.
#>
function New-TIConnectorToken {
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory = $true)]
        [string] $ComputerName,
        [Parameter(Mandatory = $true)]
        [PSCredential] $Credential
    )
    $request = "NewTIConnectorToken"

    $vendor = Get-TIConnectorVendor -ComputerName $ComputerName
    
    if (-not $vendor) {
        throw "Failed to resolve connector vendor for '$ComputerName'."
    }

    if (-not $script:ConnectorRequests.ContainsKey($vendor)) {
        throw "Vendor '$vendor' (connector '$ComputerName') is currently not supported in ConnectorRequests configuration."
    }

    if (-not $script:ConnectorRequests[$vendor].Operations.ContainsKey($request)) {
        throw "Operation '$request' is not defined for vendor '$vendor'."
    }

    $operation = $script:ConnectorRequests[$vendor].Operations[$request]

    $url = "https://{0}:{1}/{2}" -f $ComputerName, $script:ConnectorRequests[$vendor].Port, $operation.Path
    
    $payload = @{
        username = $Credential.UserName
        password = $Credential.GetNetworkCredential().Password
    } | ConvertTo-Json

    $response = Invoke-TIConnectorHttp `
        -Uri $url `
        -Method $operation.Method `
        -Body $payload `
        -ExpectedStatusCode $operation.ExpectedStatusCode

    $authHeader = $response.Headers['Authorization']
    if ([string]::IsNullOrEmpty($authHeader)) {
        throw "Authorization header is missing in connector response."
    }

    $token = ($authHeader -split '\s+')[1]
    if ([string]::IsNullOrWhiteSpace($token)) {
        throw "Failed to extract Bearer token from Authorization header."
    }

    return $token
}