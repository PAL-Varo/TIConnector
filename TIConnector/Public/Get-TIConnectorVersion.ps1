<#
.SYNOPSIS
    Retrieves the current version of the TI-Connector.

.DESCRIPTION
    Queries the connector and retrieves version information.

.PARAMETER ComputerName
    FQDN or IP address of the target connector.

.PARAMETER Credential
    PSCredential object containing connector access credentials.

.EXAMPLE
    Get-TIConnectorVersion -ComputerName "192.168.1.100" -Credential $cred
#>
function Get-TIConnectorVersion {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [string] $ComputerName,
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [PSCredential] $Credential
    )

    process {
        $version = Invoke-TIConnectorRequest -ComputerName $ComputerName -Credential $Credential -Request GetConnectorVersion
        
        $version | Add-Member -MemberType NoteProperty -Name "ComputerName" -Value $ComputerName -Force
        $version | Add-Member -MemberType NoteProperty -Name "Credential" -Value $Credential -Force

        return $version
    }
}