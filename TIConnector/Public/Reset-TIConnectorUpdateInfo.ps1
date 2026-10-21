<#
.SYNOPSIS
    Resets the update information of a TI-Connector.

.DESCRIPTION
    Resets the update information of the specified connector via REST API.

.PARAMETER ComputerName
    FQDN or IP address of the target connector.

.PARAMETER Credential
    PSCredential object containing connector access credentials.

.EXAMPLE
    Reset-TIConnectorUpdateInfo -ComputerName "192.168.1.100" -Credential $cred
#>
function Reset-TIConnectorUpdateInfo {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [string] $ComputerName,
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [PSCredential] $Credential
    )

    process {
        if ($PSCmdlet.ShouldProcess($ComputerName, "Reset TI-Connector update information")) {
            Invoke-TIConnectorRequest -ComputerName $ComputerName -Credential $Credential -Request ResetConnectorUpdateInfo
        }
    }
}