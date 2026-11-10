<#
.SYNOPSIS
    Uploads an UpdateInfo XML file for a manual connector firmware update to a TI-Connector.

.DESCRIPTION
    Uploads the UpdateInfo.xml file via multipart/form-data to the connector's 
    firmware upload endpoint. Supports pipeline context forwarding via -PassThru.

.PARAMETER ComputerName
    FQDN or IP address of the target connector.

.PARAMETER Credential
    PSCredential object containing connector access credentials.

.PARAMETER FilePath
    Path to the UpdateInfo XML file (e.g., UpdateInfo.xml).
    Aliases: Path, FullName.

.PARAMETER PassThru
    Returns the response from the connector, enriched with connection context.

.EXAMPLE
    Add-TIConnectorUpdate -ComputerName "192.168.1.100" -Credential $cred `
        -FilePath "C:\firmware\UpdateInfo.xml" -PassThru |
        Add-TIConnectorFirmware -TarPath "C:\firmware\firmware.tar" -SigPath "C:\firmware\firmware.sig"
#>
function Add-TIConnectorUpdate {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [string] $ComputerName,

        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [PSCredential] $Credential,

        [Parameter(Mandatory = $true, Position = 0, ValueFromPipelineByPropertyName = $true)]
        [Alias("Path", "FullName")]
        [string] $FilePath,

        [Parameter()]
        [switch] $PassThru
    )

    process {
        if (-not (Test-Path -Path $FilePath)) {
            $PSCmdlet.ThrowTerminatingError(
                [System.Management.Automation.ErrorRecord]::new(
                    [System.IO.FileNotFoundException]::new("UpdateInfo XML file not found at '$FilePath'."),
                    "UpdateInfoFileNotFound",
                    [System.Management.Automation.ErrorCategory]::ObjectNotFound,
                    $FilePath
                )
            )
        }

        $resolvedPath = (Get-Item -LiteralPath $FilePath).FullName
        $fileName = [System.IO.Path]::GetFileName($resolvedPath)
        $targetName = "UpdateInfo file '$fileName' on '$ComputerName'"

        if ($PSCmdlet.ShouldProcess($targetName, "Upload connector firmware UpdateInfo XML")) {
            $fileStream = $null
            $formContent = $null
            try {
                $formContent = [System.Net.Http.MultipartFormDataContent]::new()
                $fileStream = [System.IO.FileStream]::new($resolvedPath, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read)
                $fileContent = [System.Net.Http.StreamContent]::new($fileStream)
                $fileContent.Headers.ContentType = [System.Net.Http.Headers.MediaTypeHeaderValue]::Parse("text/xml")
                
                $formContent.Add($fileContent, "updateInfo", $fileName)

                $response = Invoke-TIConnectorRequest -ComputerName $ComputerName -Credential $Credential `
                    -Request AddConnectorUpdate `
                    -Body $formContent

                if ($PassThru) {
                    $output = if ($response.PSObject.Properties['data']) { $response.data } else { $response }
                    
                    if ($output -is [PSCustomObject]) {
                        if (-not $output.PSObject.Properties['ComputerName']) {
                            $output | Add-Member -NotePropertyName 'ComputerName' -NotePropertyValue $ComputerName -Force
                        }
                        if (-not $output.PSObject.Properties['Credential']) {
                            $output | Add-Member -NotePropertyName 'Credential' -NotePropertyValue $Credential -Force
                        }
                    }
                    return $output
                }
            }
            catch {
                $PSCmdlet.WriteError($_)
            }
            finally {
                if ($fileStream) { $fileStream.Dispose() }
                if ($formContent) { $formContent.Dispose() }
            }
        }
    }
}