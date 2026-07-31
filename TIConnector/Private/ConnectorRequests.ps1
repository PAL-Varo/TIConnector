$script:ConnectorRequests = @{
    Secunet = @{
        Port       = 8500
        Operations = @{
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
        }
    }
}
