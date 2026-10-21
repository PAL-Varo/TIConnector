<#
.SYNOPSIS
    Uploads a binary firmware file for a card terminal update on a TI-Connector.

.DESCRIPTION
    Uploads the firmware binary file via multipart/form-data to the connector.
    Fully supports pipeline input from Get-TIConnectorCardTerminalUpdate to automatically
    resolve the required update target without requiring manual ID entry.

.PARAMETER ComputerName
    FQDN or IP address of the target connector.

.PARAMETER Credential
    PSCredential object containing connector access credentials.

.PARAMETER InputObject
    Card terminal update object received from Get-TIConnectorCardTerminalUpdate through the pipeline.

.PARAMETER Vendor
    Product vendor ID (e.g., DECHY).
    Aliases: ProductVendorId.

.PARAMETER Product
    Product code (e.g., ST1506).
    Aliases: ProductCode.

.PARAMETER HwVersion
    Hardware version (e.g., 4.0.0).
    Aliases: HardwareVersion.

.PARAMETER TargetFwVersion
    Target firmware version to match. If omitted and only one pending update exists, it is selected automatically.

.PARAMETER FilePath
    Path to the firmware binary file (e.g., .bin).
    Aliases: Path, FullName.

.PARAMETER PassThru
    Returns the response from the connector.

.EXAMPLE
    Get-TIConnectorCardTerminalUpdate -ComputerName "192.168.1.100" -Credential $cred |
        Add-TIConnectorCardTerminalFirmware -FilePath "C:\firmware\fwupdate-tsl-5.0.0.bin"
#>
function Add-TIConnectorCardTerminalFirmware {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [string] $ComputerName,

        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [PSCredential] $Credential,

        [Parameter(ValueFromPipeline = $true)]
        [psobject] $InputObject,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [Alias("ProductVendorId")]
        [string] $Vendor,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [Alias("ProductCode")]
        [string] $Product,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [Alias("HardwareVersion")]
        [string] $HwVersion,

        [Parameter()]
        [string] $TargetFwVersion,

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
                    [System.IO.FileNotFoundException]::new("Firmware file not found at '$FilePath'."),
                    "FirmwareFileNotFound",
                    [System.Management.Automation.ErrorCategory]::ObjectNotFound,
                    $FilePath
                )
            )
        }

        $targetVendor = if ($InputObject -and $InputObject.ProductVendorId) { $InputObject.ProductVendorId } else { $Vendor }
        $targetProduct = if ($InputObject -and $InputObject.ProductCode) { $InputObject.ProductCode } else { $Product }
        $targetHw = if ($InputObject -and $InputObject.HardwareVersion) { $InputObject.HardwareVersion } else { $HwVersion }

        $updateDataList = if ($InputObject -and $InputObject.UpdateInformation) {
            @($InputObject)
        }
        else {
            Get-TIConnectorCardTerminalUpdate -ComputerName $ComputerName -Credential $Credential
        }

        if (-not $updateDataList) {
            $PSCmdlet.ThrowTerminatingError(
                [System.Management.Automation.ErrorRecord]::new(
                    [System.InvalidOperationException]::new("No card terminal update information available on '$ComputerName'."),
                    "NoTerminalUpdateInfoAvailable",
                    [System.Management.Automation.ErrorCategory]::ObjectNotFound,
                    $ComputerName
                )
            )
        }

        $candidateUpdates = @()
        foreach ($item in $updateDataList) {
            if ($targetVendor -and $item.ProductVendorId -ne $targetVendor) { continue }
            if ($targetProduct -and $item.ProductCode -ne $targetProduct) { continue }
            if ($targetHw -and $item.HardwareVersion -ne $targetHw) { continue }

            $infos = $item.UpdateInformation.cardTerminalUpdateInformation
            if ($infos) {
                foreach ($info in $infos) {
                    if ($TargetFwVersion -and $info.fwVersion -ne $TargetFwVersion) { continue }
                    $candidateUpdates += $info
                }
            }
        }

        $selectedUpdate = $null
        if ($candidateUpdates.Count -eq 1) {
            $selectedUpdate = $candidateUpdates[0]
            Write-Verbose "Auto-selected update ID '$($selectedUpdate.updateId)' for $($selectedUpdate.productVendorId)/$($selectedUpdate.productCode) (Target FW: $($selectedUpdate.fwVersion))."
        }
        elseif ($candidateUpdates.Count -gt 1) {
            $foundDetails = ($candidateUpdates | ForEach-Object { "$($_.productVendorId)/$($_.productCode) (Version: $($_.fwVersion), ID: $($_.updateId))" }) -join "; "
            $PSCmdlet.ThrowTerminatingError(
                [System.Management.Automation.ErrorRecord]::new(
                    [System.InvalidOperationException]::new("Multiple card terminal update entries match the criteria ($foundDetails). Please specify -TargetFwVersion."),
                    "MultipleMatchingUpdatesAmbiguous",
                    [System.Management.Automation.ErrorCategory]::InvalidArgument,
                    $candidateUpdates
                )
            )
        }
        else {
            $PSCmdlet.ThrowTerminatingError(
                [System.Management.Automation.ErrorRecord]::new(
                    [System.InvalidOperationException]::new("No matching card terminal update entry found on '$ComputerName'."),
                    "MatchingUpdateNotFound",
                    [System.Management.Automation.ErrorCategory]::ObjectNotFound,
                    $ComputerName
                )
            )
        }

        $resolvedUpdateId = $selectedUpdate.updateId
        $resolvedPath = (Get-Item -LiteralPath $FilePath).FullName
        $fileName = [System.IO.Path]::GetFileName($resolvedPath)
        $targetName = "Firmware file '$fileName' for update '$resolvedUpdateId' on '$ComputerName'"

        if ($PSCmdlet.ShouldProcess($targetName, "Upload card terminal firmware file")) {
            $fileStream = $null
            $formContent = $null
            try {
                $formContent = [System.Net.Http.MultipartFormDataContent]::new()
                $fileStream = [System.IO.FileStream]::new($resolvedPath, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read)
                $fileContent = [System.Net.Http.StreamContent]::new($fileStream)
                $fileContent.Headers.ContentType = [System.Net.Http.Headers.MediaTypeHeaderValue]::Parse("application/octet-stream")
                
                $formContent.Add($fileContent, "datei1", $fileName)

                $pathParams = @{
                    UpdateID = $resolvedUpdateId
                }

                $response = Invoke-TIConnectorRequest -ComputerName $ComputerName -Credential $Credential `
                    -Request AddConnectorTerminalFirmware `
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
                if ($fileStream) { $fileStream.Dispose() }
                if ($formContent) { $formContent.Dispose() }
            }
        }
    }
}