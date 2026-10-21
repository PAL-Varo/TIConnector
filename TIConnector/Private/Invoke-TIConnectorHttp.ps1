<#
.SYNOPSIS
Sends an HTTP request to a TI-Connector endpoint.

.DESCRIPTION
Invokes an HTTP request with content settings and validates the response
against the expected HTTP status codes. Supports both JSON payloads and 
advanced content types (like MultipartFormDataContent for binary uploads).
The complete web response is returned when the request succeeds.

Certificate validation is skipped because TI-Connectors commonly use
self-signed certificates. Use this helper only for trusted connector hosts.

.PARAMETER Uri
The absolute URI of the TI-Connector endpoint.

.PARAMETER Method
The HTTP method to use, for example GET, POST, PUT, or DELETE.

.PARAMETER Headers
Optional HTTP headers to include in the request. The default is an empty
hashtable.

.PARAMETER Body
Optional request body. Can be a string (JSON) or an HttpContent object.

.PARAMETER ExpectedStatusCode
One or more HTTP status codes that indicate a successful request. The
default is 200. Any other response status code causes the function to throw.

.EXAMPLE
Invoke-TIConnectorHttp -Uri 'https://connector.example:8500/rest/mgmt/ak/info' -Method 'GET' -ExpectedStatusCode 200

Sends a GET request and returns the complete web response when the connector
responds with HTTP 200.

.NOTES
This is an internal helper function and is not exported by the TIConnector
module. Requests fail when the target host is unreachable or when the
response status code is not included in ExpectedStatusCode.
#>
function Invoke-TIConnectorHttp {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string] $Uri,
        [Parameter(Mandatory)]
        [string] $Method,
        [hashtable] $Headers = @{},
        [object] $Body,
        [int[]] $ExpectedStatusCode = @(200)
    )

    try {
        $params = @{
            Uri                  = $Uri
            Method               = $Method
            Headers              = $Headers
            SkipCertificateCheck = $true
            ErrorAction          = "Stop"
        }

        if ($null -ne $Body) {
            $params.Body = $Body

            if ($Body -isnot [System.Net.Http.HttpContent]) {
                $params.ContentType = "application/json"
            }
        }

        $response = Invoke-WebRequest @params

        if ($response.StatusCode -notin $ExpectedStatusCode) {
            throw "Unexpected status code: $($response.StatusCode)"
        }

        return $response
    }
    catch {
        throw "HTTP request failed: $($_.Exception.Message)"
    }
}