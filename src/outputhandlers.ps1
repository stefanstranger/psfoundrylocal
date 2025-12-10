#region Output Handler Functions for psfoundrylocal Crescendo Module
# These functions parse the output from Foundry Local CLI commands
# and convert them to PowerShell objects for pipeline use.

<#
.SYNOPSIS
    Converts the output from 'foundry model list' to PowerShell objects.
.DESCRIPTION
    Parses the tabular output from the foundry model list command and returns
    structured FoundryLocalModel objects with Alias, Device, Task, FileSize,
    License, and ModelId properties.
.PARAMETER Output
    The raw output from the foundry model list command.
#>
function Convert-FoundryLocalModelListOutput {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [object[]]$Output
    )

    if (-not $Output) {
        return
    }

    # Convert output to string array if needed
    $lines = if ($Output -is [array]) { $Output } else { $Output -split "`n" }

    # Track if we're in the data section (after header line with dashes)
    $inDataSection = $false
    $headerFound = $false

    foreach ($line in $lines) {
        $trimmedLine = $line.Trim()

        # Skip empty lines and informational messages
        if ([string]::IsNullOrWhiteSpace($trimmedLine)) {
            continue
        }

        # Skip service status messages and download messages
        if ($trimmedLine -match '🟢|🔴|🕗|Successfully downloaded|Valid EPs:') {
            continue
        }

        # Detect header line (contains column names)
        if ($trimmedLine -match '^Alias\s+Device\s+Task\s+File Size\s+License\s+Model ID') {
            $headerFound = $true
            continue
        }

        # Detect separator line (all dashes)
        if ($trimmedLine -match '^-{20,}') {
            $inDataSection = $true
            continue
        }

        # Skip if we haven't found the header yet
        if (-not $headerFound) {
            continue
        }

        # Parse data lines - they have specific column positions based on the header
        # The output format is: Alias (30 chars), Device (10 chars), Task (14 chars), FileSize (12 chars), License (12 chars), ModelId (rest)
        if ($inDataSection -and $trimmedLine.Length -ge 40) {
            # Use regex to parse the columns more reliably
            # Match pattern: Alias, Device, Task, FileSize, License, ModelId
            $pattern = '^(?<alias>\S+)\s+(?<device>CPU|GPU|NPU)\s+(?<task>[\w,\s-]+?)\s+(?<filesize>[\d.]+\s*[KMGT]?B)\s+(?<license>\S+)\s+(?<modelid>.+)$'

            if ($trimmedLine -match $pattern) {
                $modelObject = [PSCustomObject]@{
                    PSTypeName = 'psfoundrylocal.Model'
                    Alias      = $Matches['alias'].Trim()
                    Device     = $Matches['device'].Trim()
                    Task       = $Matches['task'].Trim()
                    FileSize   = $Matches['filesize'].Trim()
                    License    = $Matches['license'].Trim()
                    ModelId    = $Matches['modelid'].Trim()
                }
                $modelObject
            }
            elseif ($trimmedLine -match '^\s+(?<device>CPU|GPU|NPU)\s+(?<task>[\w,\s-]+?)\s+(?<filesize>[\d.]+\s*[KMGT]?B)\s+(?<license>\S+)\s+(?<modelid>.+)$') {
                # Continuation line (no alias, starts with whitespace + device)
                $modelObject = [PSCustomObject]@{
                    PSTypeName = 'psfoundrylocal.Model'
                    Alias      = ''  # Continuation of previous alias group
                    Device     = $Matches['device'].Trim()
                    Task       = $Matches['task'].Trim()
                    FileSize   = $Matches['filesize'].Trim()
                    License    = $Matches['license'].Trim()
                    ModelId    = $Matches['modelid'].Trim()
                }
                $modelObject
            }
        }
    }
}

<#
.SYNOPSIS
    Converts the output from 'foundry model info' to a PowerShell object.
.DESCRIPTION
    Parses the output from the foundry model info command and returns
    a structured object with model details.
.PARAMETER Output
    The raw output from the foundry model info command.
#>
function Convert-FoundryLocalModelInfoOutput {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [object[]]$Output
    )

    if (-not $Output) {
        return
    }

    # Convert output to string array if needed
    $lines = if ($Output -is [array]) { $Output } else { $Output -split "`n" }

    $inDataSection = $false

    foreach ($line in $lines) {
        $trimmedLine = $line.Trim()

        # Skip empty lines
        if ([string]::IsNullOrWhiteSpace($trimmedLine)) {
            continue
        }

        # Detect header line
        if ($trimmedLine -match '^Alias\s+Device\s+Task\s+File Size\s+License\s+Model ID') {
            $inDataSection = $true
            continue
        }

        # Parse data line
        if ($inDataSection) {
            $pattern = '^(?<alias>\S+)\s+(?<device>CPU|GPU|NPU)\s+(?<task>[\w,\s-]+?)\s+(?<filesize>[\d.]+\s*[KMGT]?B)\s+(?<license>\S+)\s+(?<modelid>.+)$'

            if ($trimmedLine -match $pattern) {
                $modelObject = [PSCustomObject]@{
                    PSTypeName = 'psfoundrylocal.ModelInfo'
                    Alias      = $Matches['alias'].Trim()
                    Device     = $Matches['device'].Trim()
                    Task       = $Matches['task'].Trim()
                    FileSize   = $Matches['filesize'].Trim()
                    License    = $Matches['license'].Trim()
                    ModelId    = $Matches['modelid'].Trim()
                }
                return $modelObject
            }
        }
    }

    # If no structured output, return raw output
    return $Output -join "`n"
}

<#
.SYNOPSIS
    Converts the output from 'foundry model download' to a PowerShell object.
.DESCRIPTION
    Parses the output from the foundry model download command and returns
    status information.
.PARAMETER Output
    The raw output from the foundry model download command.
#>
function Convert-FoundryLocalDownloadOutput {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [object[]]$Output
    )

    if (-not $Output) {
        return
    }

    $outputText = ($Output -join "`n").Trim()

    # Check for success or error conditions
    $success = $outputText -match 'downloaded|complete|success' -or $outputText -notmatch 'error|failed|not found'

    [PSCustomObject]@{
        PSTypeName = 'psfoundrylocal.DownloadResult'
        Success    = $success
        Message    = $outputText
    }
}

<#
.SYNOPSIS
    Converts the output from 'foundry model load' to a PowerShell object.
.DESCRIPTION
    Parses the output from the foundry model load command and returns
    status information.
.PARAMETER Output
    The raw output from the foundry model load command.
#>
function Convert-FoundryLocalLoadOutput {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [object[]]$Output
    )

    if (-not $Output) {
        return
    }

    $outputText = ($Output -join "`n").Trim()

    # Check for success indicators
    $success = $outputText -match 'loaded|ready|success' -or $outputText -notmatch 'error|failed|not found'

    [PSCustomObject]@{
        PSTypeName = 'psfoundrylocal.LoadResult'
        Success    = $success
        Message    = $outputText
    }
}

<#
.SYNOPSIS
    Converts the output from 'foundry model unload' to a PowerShell object.
.DESCRIPTION
    Parses the output from the foundry model unload command and returns
    status information.
.PARAMETER Output
    The raw output from the foundry model unload command.
#>
function Convert-FoundryLocalUnloadOutput {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [object[]]$Output
    )

    if (-not $Output) {
        return
    }

    $outputText = ($Output -join "`n").Trim()

    # Check for success indicators
    $success = $outputText -match 'unloaded|success' -or $outputText -notmatch 'error|failed|not found'

    [PSCustomObject]@{
        PSTypeName = 'psfoundrylocal.UnloadResult'
        Success    = $success
        Message    = $outputText
    }
}

<#
.SYNOPSIS
    Converts the output from 'foundry service status' to a PowerShell object.
.DESCRIPTION
    Parses the service status output and returns a structured object
    with Status, Endpoint, Port, and ProcessId properties.
.PARAMETER Output
    The raw output from the foundry service status command.
#>
function Convert-FoundryLocalServiceStatusOutput {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [object[]]$Output
    )

    if (-not $Output) {
        return
    }

    $outputText = ($Output -join "`n").Trim()

    $serviceStatus = [PSCustomObject]@{
        PSTypeName = 'psfoundrylocal.ServiceStatus'
        IsRunning  = $false
        Endpoint   = $null
        Port       = $null
        ProcessId  = $null
        Message    = $outputText
    }

    # Parse running status - check for running indicators (handles emoji encoding issues)
    # Patterns: "🟢 Service is Started on http://127.0.0.1:44549/, PID 19804!"
    #           "service is running on http://..."
    if ($outputText -match 'running|Started|is running') {
        $serviceStatus.IsRunning = $true
        # Try to parse endpoint if present
        if ($outputText -match 'http://([^/\s]+):(\d+)') {
            $serviceStatus.Endpoint = "http://$($Matches[1]):$($Matches[2])/"
            $serviceStatus.Port = [int]$Matches[2]
        }
        if ($outputText -match 'PID\s*(\d+)') {
            $serviceStatus.ProcessId = [int]$Matches[1]
        }
    }
    elseif ($outputText -match 'not running|stopped') {
        $serviceStatus.IsRunning = $false
    }

    return $serviceStatus
}

<#
.SYNOPSIS
    Converts the output from 'foundry service ps' to PowerShell objects.
.DESCRIPTION
    Parses the list of loaded models and returns structured objects.
.PARAMETER Output
    The raw output from the foundry service ps command.
#>
function Convert-FoundryLocalServicePsOutput {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [object[]]$Output
    )

    if (-not $Output) {
        return
    }

    $outputText = ($Output -join "`n").Trim()

    # Check if no models are loaded
    if ($outputText -match 'No models.*loaded|empty') {
        return [PSCustomObject]@{
            PSTypeName   = 'psfoundrylocal.LoadedModels'
            ModelsLoaded = 0
            Models       = @()
            Message      = $outputText
        }
    }

    # Parse loaded models - format may vary
    $models = @()
    $lines = $Output | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }

    foreach ($line in $lines) {
        $trimmed = $line.Trim()
        # Skip header and informational lines
        if ($trimmed -match '^(Alias|Model|Name|-)' -or $trimmed -match '🟢|🔴') {
            continue
        }
        if ($trimmed.Length -gt 0) {
            $models += $trimmed
        }
    }

    return [PSCustomObject]@{
        PSTypeName   = 'psfoundrylocal.LoadedModels'
        ModelsLoaded = $models.Count
        Models       = $models
        Message      = $outputText
    }
}

<#
.SYNOPSIS
    Converts the output from 'foundry service start' to a PowerShell object.
.DESCRIPTION
    Parses the service start output and returns status information.
.PARAMETER Output
    The raw output from the foundry service start command.
#>
function Convert-FoundryLocalServiceStartOutput {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [object[]]$Output
    )

    if (-not $Output) {
        return
    }

    $outputText = ($Output -join "`n").Trim()

    $result = [PSCustomObject]@{
        PSTypeName = 'psfoundrylocal.ServiceStartResult'
        Success    = $false
        Endpoint   = $null
        Port       = $null
        ProcessId  = $null
        Message    = $outputText
    }

    if ($outputText -match 'started|running|Started') {
        $result.Success = $true

        if ($outputText -match 'http://([^/\s]+):(\d+)') {
            $result.Endpoint = "http://$($Matches[1]):$($Matches[2])/"
            $result.Port = [int]$Matches[2]
        }
        if ($outputText -match 'PID\s*(\d+)') {
            $result.ProcessId = [int]$Matches[1]
        }
    }

    return $result
}

<#
.SYNOPSIS
    Converts the output from 'foundry service stop' to a PowerShell object.
.DESCRIPTION
    Parses the service stop output and returns status information.
.PARAMETER Output
    The raw output from the foundry service stop command.
#>
function Convert-FoundryLocalServiceStopOutput {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [object[]]$Output
    )

    if (-not $Output) {
        return
    }

    $outputText = ($Output -join "`n").Trim()

    $success = $outputText -match 'stopped|Stopped' -or $outputText -notmatch 'error|failed'

    return [PSCustomObject]@{
        PSTypeName = 'psfoundrylocal.ServiceStopResult'
        Success    = $success
        Message    = $outputText
    }
}

<#
.SYNOPSIS
    Converts the output from 'foundry service restart' to a PowerShell object.
.DESCRIPTION
    Parses the service restart output and returns status information.
.PARAMETER Output
    The raw output from the foundry service restart command.
#>
function Convert-FoundryLocalServiceRestartOutput {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [object[]]$Output
    )

    if (-not $Output) {
        return
    }

    $outputText = ($Output -join "`n").Trim()

    $result = [PSCustomObject]@{
        PSTypeName = 'psfoundrylocal.ServiceRestartResult'
        Success    = $false
        Endpoint   = $null
        Port       = $null
        ProcessId  = $null
        Message    = $outputText
    }

    if ($outputText -match 'started|running|restarted|Started') {
        $result.Success = $true

        if ($outputText -match 'http://([^/\s]+):(\d+)') {
            $result.Endpoint = "http://$($Matches[1]):$($Matches[2])/"
            $result.Port = [int]$Matches[2]
        }
        if ($outputText -match 'PID\s*(\d+)') {
            $result.ProcessId = [int]$Matches[1]
        }
    }

    return $result
}

<#
.SYNOPSIS
    Converts the output from 'foundry cache list' to PowerShell objects.
.DESCRIPTION
    Parses the cache list output and returns structured objects for each cached model.
.PARAMETER Output
    The raw output from the foundry cache list command.
#>
function Convert-FoundryLocalCacheListOutput {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [object[]]$Output
    )

    if (-not $Output) {
        return
    }

    # Convert output to string array if needed
    $lines = if ($Output -is [array]) { $Output } else { $Output -split "`n" }

    $inDataSection = $false

    foreach ($line in $lines) {
        $trimmedLine = $line.Trim()

        # Skip empty lines
        if ([string]::IsNullOrWhiteSpace($trimmedLine)) {
            continue
        }

        # Skip header line
        if ($trimmedLine -match '^\s*Alias\s+Model ID' -or $trimmedLine -match 'Models cached') {
            $inDataSection = $true
            continue
        }

        # Parse cache entries - handles both emoji and non-emoji formats
        # Format: "💾 alias    model-id" or just "alias    model-id"
        # The emoji may appear garbled due to encoding
        if ($inDataSection) {
            # Try to match with any leading character(s) before the alias
            if ($trimmedLine -match '^[^\w]*(?<alias>[\w\.-]+)\s+(?<modelid>[\w\.-]+.*)$' -and $trimmedLine -notmatch 'Cache directory') {
                [PSCustomObject]@{
                    PSTypeName = 'psfoundrylocal.CachedModel'
                    Alias      = $Matches['alias'].Trim()
                    ModelId    = $Matches['modelid'].Trim()
                }
            }
        }
    }
}

<#
.SYNOPSIS
    Converts the output from 'foundry cache location' to a PowerShell object.
.DESCRIPTION
    Parses the cache location output and returns the directory path.
.PARAMETER Output
    The raw output from the foundry cache location command.
#>
function Convert-FoundryLocalCacheLocationOutput {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [object[]]$Output
    )

    if (-not $Output) {
        return
    }

    $outputText = ($Output -join "`n").Trim()

    $cachePath = $null

    # Parse: "💾 Cache directory path: C:\Users\...\cache\models"
    if ($outputText -match 'Cache directory path:\s*(?<path>.+)$') {
        $cachePath = $Matches['path'].Trim()
    }
    # Fallback: just a path
    elseif ($outputText -match '^[A-Za-z]:\\' -or $outputText -match '^/') {
        $cachePath = $outputText.Trim()
    }

    return [PSCustomObject]@{
        PSTypeName = 'psfoundrylocal.CacheLocation'
        Path       = $cachePath
        Exists     = if ($cachePath) { Test-Path $cachePath } else { $false }
    }
}

<#
.SYNOPSIS
    Converts the output from 'foundry cache cd' to a PowerShell object.
.DESCRIPTION
    Parses the cache cd output and returns status information.
.PARAMETER Output
    The raw output from the foundry cache cd command.
#>
function Convert-FoundryLocalCacheCdOutput {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [object[]]$Output
    )

    if (-not $Output) {
        return
    }

    $outputText = ($Output -join "`n").Trim()

    $success = $outputText -notmatch 'error|failed|not found|invalid'

    return [PSCustomObject]@{
        PSTypeName = 'psfoundrylocal.CacheLocationChange'
        Success    = $success
        Message    = $outputText
    }
}

<#
.SYNOPSIS
    Converts the output from 'foundry cache remove' to a PowerShell object.
.DESCRIPTION
    Parses the cache remove output and returns status information.
.PARAMETER Output
    The raw output from the foundry cache remove command.
#>
function Convert-FoundryLocalCacheRemoveOutput {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [object[]]$Output
    )

    if (-not $Output) {
        return
    }

    $outputText = ($Output -join "`n").Trim()

    $success = $outputText -match 'removed|deleted|success' -or $outputText -notmatch 'error|failed|not found'

    return [PSCustomObject]@{
        PSTypeName = 'psfoundrylocal.CacheRemoveResult'
        Success    = $success
        Message    = $outputText
    }
}

#endregion Output Handler Functions
