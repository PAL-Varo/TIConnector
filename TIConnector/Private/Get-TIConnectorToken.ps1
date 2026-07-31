<#
.SYNOPSIS
    Gets a valid authentication token for a TI-Connector.

.DESCRIPTION
    Returns a previously acquired bearer token when it was used within the
    last four minutes. If no valid cached token exists, requests a new token
    from the TI-Connector by using the supplied credentials and stores it for
    subsequent requests.

    The token cache is maintained separately for each connector and its last
    use time is updated whenever a cached token is returned.

.PARAMETER ComputerName
    The FQDN or IP address of the target TI-Connector.

.PARAMETER Credential
    A PSCredential object containing the username and password used to obtain
    an authentication token when a new token is required.

.OUTPUTS
    System.String

    The cached or newly requested bearer token.

.EXAMPLE
    $token = Get-TIConnectorToken -ComputerName 'connector.example' -Credential $credential

    Returns a valid token for the specified connector, reusing a recent token
    when available.

.NOTES
    This is an internal helper function and is not exported by the
    TIConnector module. A new token is requested after the cached token has
    not been used for four minutes.
#>
function Get-TIConnectorToken {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$ComputerName,
        [Parameter(Mandatory)]
        [PSCredential]$Credential
    )

    $key = $ComputerName.ToLower()

    if ($script:ConnectorSessions.ContainsKey($key)) {
        $session = $script:ConnectorSessions[$key]
        
        if ($session.LastUsedAt -gt (Get-Date).AddMinutes(-4)) {
            $session.LastUsedAt = Get-Date
            return $session.Token
        }
    }

    $token = New-TIConnectorToken -ComputerName $ComputerName -Credential $Credential

    $script:ConnectorSessions[$key] = @{
        Token      = $token
        LastUsedAt = Get-Date
    }

    return $token
}