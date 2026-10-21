<#
.SYNOPSIS
    Retrieves the firmware update information for a TI-Connector.

.DESCRIPTION
    Queries update information for the connector via the REST API.
    The returned object is enriched with ComputerName and Credential properties.

.PARAMETER ComputerName
    FQDN or IP address of the target connector.

.PARAMETER Credential
    PSCredential object containing connector access credentials.

.EXAMPLE
    Get-TIConnectorUpdate -ComputerName "192.168.1.100" -Credential $cred
#>
function Get-TIConnectorUpdate {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [string] $ComputerName,
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [PSCredential] $Credential
    )

    process {
        $updateInfo = Invoke-TIConnectorRequest -ComputerName $ComputerName -Credential $Credential -Request GetConnectorUpdateInformation

        if ($updateInfo) {
            $updateInfo | Add-Member -MemberType NoteProperty -Name "ComputerName" -Value $ComputerName -Force
            $updateInfo | Add-Member -MemberType NoteProperty -Name "Credential" -Value $Credential -Force
            return $updateInfo
        }
    }
}