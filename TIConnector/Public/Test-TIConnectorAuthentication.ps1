<#
.SYNOPSIS
    Tests whether the provided credentials are valid for the specified TI-Connector.

.DESCRIPTION
    Attempts to request a fresh authentication token directly from the connector's 
    REST API. Returns $true if authentication succeeds, or $false if it fails.

.PARAMETER ComputerName
    FQDN or IP address of the target connector.

.PARAMETER Credential
    PSCredential object containing the username and password to test.

.EXAMPLE
    Test-TIConnectorAuthentication -ComputerName "konnektor.local" -Credential $cred
    Returns $true if authentication succeeds.
#>
function Test-TIConnectorAuthentication {
    [CmdletBinding()]
    [OutputType([bool])]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [string] $ComputerName,
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [PSCredential] $Credential
    )

    process {
        try {
            $token = New-TIConnectorToken -ComputerName $ComputerName -Credential $Credential
            return [bool](-not [string]::IsNullOrWhiteSpace($token))
        }
        catch {
            Write-Verbose "Authentication failed for '$ComputerName': $($_.Exception.Message)"
            return $false
        }
    }
}