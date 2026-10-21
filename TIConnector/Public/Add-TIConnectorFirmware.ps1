<#
.SYNOPSIS
    Uploads firmware archive and signature files for a manual connector update on a TI-Connector.

.DESCRIPTION
    Uploads 'firmware.tar' (datei1) and 'firmware.sig' (datei2) via multipart/form-data 
    to the connector's firmware upload endpoint. Automatically resolves the update ID 
    if not explicitly specified.

.PARAMETER ComputerName
    FQDN or IP address of the target connector.

.PARAMETER Credential
    PSCredential object containing connector access credentials.

.PARAMETER UpdateId
    The unique update identifier. If omitted, the function attempts to resolve it automatically.

.PARAMETER TargetFwVersion
    Target firmware version to match when auto-resolving the update ID.

.PARAMETER TarPath
    Path to the firmware tarball file (firmware.tar).
    Aliases: Tar, Archive, Path

.PARAMETER SigPath
    Path to the signature file (firmware.sig).
    Aliases: Sig, Signature

.PARAMETER PassThru
    Returns the response from the connector.

.EXAMPLE
    Add-TIConnectorFirmware -ComputerName "192.168.1.100" -Credential $cred `
        -TargetFwVersion "6.1.4" -TarPath "C:\firmware\firmware.tar" -SigPath "C:\firmware\firmware.sig" -PassThru
#>
function Add-TIConnectorFirmware {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [string] $ComputerName,

        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [PSCredential] $Credential,

        [Parameter()]
        [Alias("Id", "FirmwareUpdateId")]
        [string] $UpdateId,

        [Parameter()]
        [string] $TargetFwVersion,

        [Parameter(Mandatory = $true)]
        [Alias("Tar", "Archive", "Path")]
        [string] $TarPath,

        [Parameter(Mandatory = $true)]
        [Alias("Sig", "Signature")]
        [string] $SigPath,

        [Parameter()]
        [switch] $PassThru
    )

    process {
        foreach ($p in @($TarPath, $SigPath)) {
            if (-not (Test-Path -Path $p)) {
                $PSCmdlet.ThrowTerminatingError(
                    [System.Management.Automation.ErrorRecord]::new(
                        [System.IO.FileNotFoundException]::new("Firmware file not found at '$p'."),
                        "FirmwareFileNotFound",
                        [System.Management.Automation.ErrorCategory]::ObjectNotFound,
                        $p
                    )
                )
            }
        }

        if (-not $UpdateId) {
            Write-Verbose "Resolving connector update ID..."
            $updateInfo = Get-TIConnectorUpdate -ComputerName $ComputerName -Credential $Credential
            $candidates = $updateInfo.connectorUpdateInformation

            if ($TargetFwVersion) {
                $candidates = $candidates | Where-Object { $_.fwVersion -eq $TargetFwVersion }
            }

            if (@($candidates).Count -eq 1) {
                $UpdateId = $candidates[0].updateId
                Write-Verbose "Auto-resolved UpdateId: $UpdateId"
            }
            elseif (@($candidates).Count -gt 1) {
                $PSCmdlet.ThrowTerminatingError(
                    [System.Management.Automation.ErrorRecord]::new(
                        [System.InvalidOperationException]::new("Multiple connector update entries match. Please specify -TargetFwVersion or -UpdateId."),
                        "MultipleUpdatesAmbiguous",
                        [System.Management.Automation.ErrorCategory]::InvalidArgument,
                        $candidates
                    )
                )
            }
            else {
                $PSCmdlet.ThrowTerminatingError(
                    [System.Management.Automation.ErrorRecord]::new(
                        [System.InvalidOperationException]::new("No pending connector update entry found to attach firmware to."),
                        "UpdateNotFound",
                        [System.Management.Automation.ErrorCategory]::ObjectNotFound,
                        $ComputerName
                    )
                )
            }
        }

        $tarResolved = (Get-Item -LiteralPath $TarPath).FullName
        $sigResolved = (Get-Item -LiteralPath $SigPath).FullName
        $tarName = [System.IO.Path]::GetFileName($tarResolved)
        $sigName = [System.IO.Path]::GetFileName($sigResolved)

        $targetName = "Firmware files ($tarName, $sigName) for update '$UpdateId' on '$ComputerName'"

        if ($PSCmdlet.ShouldProcess($targetName, "Upload connector firmware binary and signature")) {
            $tarStream = $null
            $sigStream = $null
            $formContent = $null
            try {
                $formContent = [System.Net.Http.MultipartFormDataContent]::new()

                $tarStream = [System.IO.FileStream]::new($tarResolved, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read)
                $tarContent = [System.Net.Http.StreamContent]::new($tarStream)
                $tarContent.Headers.ContentType = [System.Net.Http.Headers.MediaTypeHeaderValue]::Parse("application/x-tar")
                $formContent.Add($tarContent, "datei1", $tarName)

                $sigStream = [System.IO.FileStream]::new($sigResolved, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read)
                $sigContent = [System.Net.Http.StreamContent]::new($sigStream)
                $sigContent.Headers.ContentType = [System.Net.Http.Headers.MediaTypeHeaderValue]::Parse("application/octet-stream")
                $formContent.Add($sigContent, "datei2", $sigName)

                $pathParams = @{
                    UpdateID = $UpdateId
                }

                $response = Invoke-TIConnectorRequest -ComputerName $ComputerName -Credential $Credential `
                    -Request AddConnectorFirmware `
                    -PathParameters $pathParams `
                    -Body $formContent

                if ($PassThru) {
                    if ($response.PSObject.Properties['data']) {
                        return $response.data
                    }
                    return $response
                }
            }
            catch {
                $PSCmdlet.WriteError($_)
            }
            finally {
                if ($tarStream) {$tarStream.Dispose() }
                if ($sigStream) {$sigStream.Dispose() }
                if ($formContent) {$formContent.Dispose() }
            }
        }
    }
}