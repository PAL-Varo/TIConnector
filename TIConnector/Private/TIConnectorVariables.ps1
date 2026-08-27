# In-Memory Cache for active connector session tokens
$script:ConnectorSessions = @{}

# In-Memory Cache for resolved vendors
$script:TIConnectorVendorCache = @{}

<#
This file defines the internal REST API configuration for supported
TI-Connector implementations.

Each connector entry contains its management port and a list of supported
operations. Every operation specifies the relative request path, HTTP method,
and HTTP status code expected for a successful response.

The configuration is consumed by the module's internal request helpers and is
not exported as part of the public module API.
#>
$script:ConnectorRequests = @{
    SECUN = @{
        Port       = 8500
        Operations = @{
            NewTIConnectorToken                   = @{
                Path               = "rest/mgmt/ak/konten/login"
                Method             = "Post"
                ExpectedStatusCode = 204
            }
            RemoveConnectorSession                = @{
                Path               = "rest/mgmt/ak/konten/profil/logout"
                Method             = "Delete"
                ExpectedStatusCode = 204
            }
            GetConnectorStatus                    = @{
                Path               = "rest/mgmt/ak/dienste/status"
                Method             = "Get"
                ExpectedStatusCode = 200
            }
            RestartConnector                      = @{
                Path               = "rest/mgmt/nk/system"
                Method             = "Post"
                ExpectedStatusCode = 200
            }
            GetConnectorCardTerminal              = @{
                Path               = "rest/mgmt/ak/dienste/kartenterminals/{CardTerminalID}/erweitert"
                Method             = "Get"
                ExpectedStatusCode = 200
            }
            GetConnectorCardTerminals             = @{
                Path               = "rest/mgmt/ak/dienste/kartenterminals"
                Method             = "Get"
                ExpectedStatusCode = 200
            }
            EnableConnectorCardTerminal           = @{
                Path               = "rest/mgmt/ak/dienste/kartenterminals/{CardTerminalID}/aktivieren"
                Method             = "Put"
                ExpectedStatusCode = 200
            }
            EnableConnectorCardTerminalConnection = @{
                Path               = "rest/mgmt/ak/dienste/kartenterminals/{CardTerminalID}/verbinden"
                Method             = "Put"
                ExpectedStatusCode = 200
            }
            DisableConnectorCardTerminal          = @{
                Path               = "rest/mgmt/ak/dienste/kartenterminals/{CardTerminalID}/aktivieren"
                Method             = "Delete"
                ExpectedStatusCode = 200
            }
            RemoveConnectorCardTerminalAssignment = @{
                Path               = "rest/mgmt/ak/dienste/kartenterminals/{CardTerminalID}/zuweisen"
                Method             = "Delete"
                ExpectedStatusCode = 200
            }
            RemoveConnectorCardTerminal           = @{
                Path               = "rest/mgmt/ak/dienste/kartenterminals/{CardTerminalID}"
                Method             = "Delete"
                ExpectedStatusCode = 200
            }
            GetConnectorContext                   = @{
                Path               = "rest/mgmt/ak/info"
                Method             = "Get"
                ExpectedStatusCode = 200
            }
            GetConnectorCards                     = @{
                Path               = "rest/mgmt/ak/dienste/karten"
                Method             = "Get"
                ExpectedStatusCode = 200
            }
            GetConnectorCard                      = @{
                Path               = "rest/mgmt/ak/dienste/karten/{CardHandle}"
                Method             = "Get"
                ExpectedStatusCode = 200
            }
            GetConnectorLogSetting                = @{
                Path               = "rest/mgmt/nk/protokoll/einstellungen"
                Method             = "Get"
                ExpectedStatusCode = 200
            }
            SetConnectorLogSetting                = @{
                Path               = "rest/mgmt/nk/protokoll/einstellungen?strict=true"
                Method             = "Put"
                ExpectedStatusCode = 200
            }
        }
    }
}
