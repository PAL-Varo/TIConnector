<#
.SYNOPSIS
    Triggers an update check on a TI-Connector.

.DESCRIPTION
    Instructs the specified connector via the REST API to check for updates 
    against the central service (KSR).

.PARAMETER ComputerName
    FQDN or IP address of the target connector.

.PARAMETER Credential
    PSCredential object containing connector access credentials.

.EXAMPLE
    Invoke-TIConnectorUpdateCheck -ComputerName "192.168.1.100" -Credential $cred
#>
function Invoke-TIConnectorUpdateCheck {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [string] $ComputerName,
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [PSCredential] $Credential
    )

    process {
        if ($PSCmdlet.ShouldProcess($ComputerName, "Trigger update check on TI-Connector")) {
            Invoke-TIConnectorRequest -ComputerName $ComputerName -Credential $Credential -Request InvokeConnectorUpdateCheck
        }
    }
}