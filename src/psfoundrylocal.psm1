# Module created by Microsoft.PowerShell.Crescendo
class PowerShellCustomFunctionAttribute : System.Attribute { 
    [bool]$RequiresElevation
    [string]$Source
    PowerShellCustomFunctionAttribute() { $this.RequiresElevation = $false; $this.Source = "Microsoft.PowerShell.Crescendo" }
    PowerShellCustomFunctionAttribute([bool]$rElevation) {
        $this.RequiresElevation = $rElevation
        $this.Source = "Microsoft.PowerShell.Crescendo"
    }
}

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


function Get-FoundryLocalModel
{
[PowerShellCustomFunctionAttribute(RequiresElevation=$False)]
[CmdletBinding()]

param(
[Parameter()]
[string]$Filter
    )

BEGIN {
    $__PARAMETERMAP = @{
         Filter = @{
               OriginalName = '--filter'
               OriginalPosition = '0'
               Position = '2147483647'
               ParameterType = 'string'
               ApplyToExecutable = $False
               NoGap = $False
               }
    }

    $__outputHandlers = @{
        Default = @{ StreamOutput = $False; Handler = 'Convert-FoundryLocalModelListOutput' }
    }
}

PROCESS {
    $__boundParameters = $PSBoundParameters
    $__defaultValueParameters = $PSCmdlet.MyInvocation.MyCommand.Parameters.Values.Where({$_.Attributes.Where({$_.TypeId.Name -eq "PSDefaultValueAttribute"})}).Name
    $__defaultValueParameters.Where({ !$__boundParameters["$_"] }).ForEach({$__boundParameters["$_"] = get-variable -value $_})
    $__commandArgs = @()
    $MyInvocation.MyCommand.Parameters.Values.Where({$_.SwitchParameter -and $_.Name -notmatch "Debug|Whatif|Confirm|Verbose" -and ! $__boundParameters[$_.Name]}).ForEach({$__boundParameters[$_.Name] = [switch]::new($false)})
    if ($__boundParameters["Debug"]){wait-debugger}
    $__commandArgs += 'model'
    $__commandArgs += 'list'
    foreach ($paramName in $__boundParameters.Keys|
            Where-Object {!$__PARAMETERMAP[$_].ApplyToExecutable}|
            Sort-Object {$__PARAMETERMAP[$_].OriginalPosition}) {
        $value = $__boundParameters[$paramName]
        $param = $__PARAMETERMAP[$paramName]
        if ($param) {
            if ($value -is [switch]) {
                 if ($value.IsPresent) {
                     if ($param.OriginalName) { $__commandArgs += $param.OriginalName }
                 }
                 elseif ($param.DefaultMissingValue) { $__commandArgs += $param.DefaultMissingValue }
            }
            elseif ( $param.NoGap ) {
                $pFmt = "{0}{1}"
                if($value -match "\s") { $pFmt = "{0}""{1}""" }
                $__commandArgs += $pFmt -f $param.OriginalName, $value
            }
            else {
                if($param.OriginalName) { $__commandArgs += $param.OriginalName }
                $__commandArgs += $value | Foreach-Object {$_}
            }
        }
    }
    $__commandArgs = $__commandArgs | Where-Object {$_ -ne $null}
    if ($__boundParameters["Debug"]){wait-debugger}
    if ( $__boundParameters["Verbose"]) {
         Write-Verbose -Verbose -Message foundry
         $__commandArgs | Write-Verbose -Verbose
    }
    $__handlerInfo = $__outputHandlers[$PSCmdlet.ParameterSetName]
    if (! $__handlerInfo ) {
        $__handlerInfo = $__outputHandlers["Default"] # Guaranteed to be present
    }
    $__handler = $__handlerInfo.Handler
    if ( $PSCmdlet.ShouldProcess("foundry $__commandArgs")) {
    # check for the application and throw if it cannot be found
        if ( -not (Get-Command -ErrorAction Ignore "foundry")) {
          throw "Cannot find executable 'foundry'"
        }
        if ( $__handlerInfo.StreamOutput ) {
            & "foundry" $__commandArgs | & $__handler
        }
        else {
            $result = & "foundry" $__commandArgs
            & $__handler $result
        }
    }
  } # end PROCESS

<#
.SYNOPSIS
Get a list of available Foundry Local models.

.DESCRIPTION
Lists all available models for Foundry Local. Returns model information including alias, device type, task, file size, license, and model ID.

.PARAMETER Filter
Filter models by a specific criteria. Format: key=value. Supported keys: device (CPU, GPU, NPU), task (chat-completion, text-generation), alias, provider. Prefix value with ! for negation. Use * suffix for wildcard matching on alias.



.EXAMPLE
PS> Get-FoundryLocalModel

Lists all available models.
Original Command: foundry model list


.EXAMPLE
PS> Get-FoundryLocalModel -Filter 'device=GPU'

Lists models filtered by GPU device.
Original Command: foundry model list --filter device=GPU


.EXAMPLE
PS> Get-FoundryLocalModel -Filter 'task=chat-completion'

Lists models filtered by chat-completion task.
Original Command: foundry model list --filter task=chat-completion


#>
}


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


function Get-FoundryLocalModelInfo
{
[PowerShellCustomFunctionAttribute(RequiresElevation=$False)]
[CmdletBinding()]

param(
[Parameter(Mandatory=$true)]
[string]$Model,
[ValidateSet('Auto', 'CPU', 'GPU', 'NPU')]
[Parameter()]
[PSDefaultValue(Value="Auto")]
[string]$Device = "Auto",
[Parameter()]
[switch]$License
    )

BEGIN {
    $__PARAMETERMAP = @{
         Model = @{
               OriginalName = ''
               OriginalPosition = '0'
               Position = '2147483647'
               ParameterType = 'string'
               ApplyToExecutable = $False
               NoGap = $False
               }
         Device = @{
               OriginalName = '--device'
               OriginalPosition = '0'
               Position = '2147483647'
               ParameterType = 'string'
               ApplyToExecutable = $False
               NoGap = $False
               }
         License = @{
               OriginalName = '--license'
               OriginalPosition = '0'
               Position = '2147483647'
               ParameterType = 'switch'
               ApplyToExecutable = $False
               NoGap = $False
               }
    }

    $__outputHandlers = @{
        Default = @{ StreamOutput = $False; Handler = 'Convert-FoundryLocalModelInfoOutput' }
    }
}

PROCESS {
    $__boundParameters = $PSBoundParameters
    $__defaultValueParameters = $PSCmdlet.MyInvocation.MyCommand.Parameters.Values.Where({$_.Attributes.Where({$_.TypeId.Name -eq "PSDefaultValueAttribute"})}).Name
    $__defaultValueParameters.Where({ !$__boundParameters["$_"] }).ForEach({$__boundParameters["$_"] = get-variable -value $_})
    $__commandArgs = @()
    $MyInvocation.MyCommand.Parameters.Values.Where({$_.SwitchParameter -and $_.Name -notmatch "Debug|Whatif|Confirm|Verbose" -and ! $__boundParameters[$_.Name]}).ForEach({$__boundParameters[$_.Name] = [switch]::new($false)})
    if ($__boundParameters["Debug"]){wait-debugger}
    $__commandArgs += 'model'
    $__commandArgs += 'info'
    foreach ($paramName in $__boundParameters.Keys|
            Where-Object {!$__PARAMETERMAP[$_].ApplyToExecutable}|
            Sort-Object {$__PARAMETERMAP[$_].OriginalPosition}) {
        $value = $__boundParameters[$paramName]
        $param = $__PARAMETERMAP[$paramName]
        if ($param) {
            if ($value -is [switch]) {
                 if ($value.IsPresent) {
                     if ($param.OriginalName) { $__commandArgs += $param.OriginalName }
                 }
                 elseif ($param.DefaultMissingValue) { $__commandArgs += $param.DefaultMissingValue }
            }
            elseif ( $param.NoGap ) {
                $pFmt = "{0}{1}"
                if($value -match "\s") { $pFmt = "{0}""{1}""" }
                $__commandArgs += $pFmt -f $param.OriginalName, $value
            }
            else {
                if($param.OriginalName) { $__commandArgs += $param.OriginalName }
                $__commandArgs += $value | Foreach-Object {$_}
            }
        }
    }
    $__commandArgs = $__commandArgs | Where-Object {$_ -ne $null}
    if ($__boundParameters["Debug"]){wait-debugger}
    if ( $__boundParameters["Verbose"]) {
         Write-Verbose -Verbose -Message foundry
         $__commandArgs | Write-Verbose -Verbose
    }
    $__handlerInfo = $__outputHandlers[$PSCmdlet.ParameterSetName]
    if (! $__handlerInfo ) {
        $__handlerInfo = $__outputHandlers["Default"] # Guaranteed to be present
    }
    $__handler = $__handlerInfo.Handler
    if ( $PSCmdlet.ShouldProcess("foundry $__commandArgs")) {
    # check for the application and throw if it cannot be found
        if ( -not (Get-Command -ErrorAction Ignore "foundry")) {
          throw "Cannot find executable 'foundry'"
        }
        if ( $__handlerInfo.StreamOutput ) {
            & "foundry" $__commandArgs | & $__handler
        }
        else {
            $result = & "foundry" $__commandArgs
            & $__handler $result
        }
    }
  } # end PROCESS

<#
.SYNOPSIS
Get detailed information about a specific Foundry Local model.

.DESCRIPTION
Displays detailed information about a specific Foundry Local model.

.PARAMETER Model
Name or alias of the model to get information about.


.PARAMETER Device
Select a model that is valid for the specified device. Valid values: Auto, CPU, GPU, NPU.


.PARAMETER License
View full terms of model license.



.EXAMPLE
PS> Get-FoundryLocalModelInfo -Model 'phi-4-mini'

Gets detailed information about the phi-4-mini model.
Original Command: foundry model info phi-4-mini


.EXAMPLE
PS> Get-FoundryLocalModelInfo -Model 'phi-4-mini' -Device GPU

Gets information about the phi-4-mini model for GPU device.
Original Command: foundry model info phi-4-mini --device GPU


#>
}


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


function Save-FoundryLocalModel
{
[PowerShellCustomFunctionAttribute(RequiresElevation=$False)]
[CmdletBinding(SupportsShouldProcess=$true)]

param(
[Parameter(Mandatory=$true)]
[string]$Model,
[ValidateSet('Auto', 'CPU', 'GPU', 'NPU')]
[Parameter()]
[PSDefaultValue(Value="Auto")]
[string]$Device = "Auto",
[Parameter()]
[switch]$Force,
[Parameter()]
[string]$Token
    )

BEGIN {
    $__PARAMETERMAP = @{
         Model = @{
               OriginalName = ''
               OriginalPosition = '0'
               Position = '2147483647'
               ParameterType = 'string'
               ApplyToExecutable = $False
               NoGap = $False
               }
         Device = @{
               OriginalName = '--device'
               OriginalPosition = '0'
               Position = '2147483647'
               ParameterType = 'string'
               ApplyToExecutable = $False
               NoGap = $False
               }
         Force = @{
               OriginalName = '--force'
               OriginalPosition = '0'
               Position = '2147483647'
               ParameterType = 'switch'
               ApplyToExecutable = $False
               NoGap = $False
               }
         Token = @{
               OriginalName = '--token'
               OriginalPosition = '0'
               Position = '2147483647'
               ParameterType = 'string'
               ApplyToExecutable = $False
               NoGap = $False
               }
    }

    $__outputHandlers = @{
        Default = @{ StreamOutput = $False; Handler = 'Convert-FoundryLocalDownloadOutput' }
    }
}

PROCESS {
    $__boundParameters = $PSBoundParameters
    $__defaultValueParameters = $PSCmdlet.MyInvocation.MyCommand.Parameters.Values.Where({$_.Attributes.Where({$_.TypeId.Name -eq "PSDefaultValueAttribute"})}).Name
    $__defaultValueParameters.Where({ !$__boundParameters["$_"] }).ForEach({$__boundParameters["$_"] = get-variable -value $_})
    $__commandArgs = @()
    $MyInvocation.MyCommand.Parameters.Values.Where({$_.SwitchParameter -and $_.Name -notmatch "Debug|Whatif|Confirm|Verbose" -and ! $__boundParameters[$_.Name]}).ForEach({$__boundParameters[$_.Name] = [switch]::new($false)})
    if ($__boundParameters["Debug"]){wait-debugger}
    $__commandArgs += 'model'
    $__commandArgs += 'download'
    foreach ($paramName in $__boundParameters.Keys|
            Where-Object {!$__PARAMETERMAP[$_].ApplyToExecutable}|
            Sort-Object {$__PARAMETERMAP[$_].OriginalPosition}) {
        $value = $__boundParameters[$paramName]
        $param = $__PARAMETERMAP[$paramName]
        if ($param) {
            if ($value -is [switch]) {
                 if ($value.IsPresent) {
                     if ($param.OriginalName) { $__commandArgs += $param.OriginalName }
                 }
                 elseif ($param.DefaultMissingValue) { $__commandArgs += $param.DefaultMissingValue }
            }
            elseif ( $param.NoGap ) {
                $pFmt = "{0}{1}"
                if($value -match "\s") { $pFmt = "{0}""{1}""" }
                $__commandArgs += $pFmt -f $param.OriginalName, $value
            }
            else {
                if($param.OriginalName) { $__commandArgs += $param.OriginalName }
                $__commandArgs += $value | Foreach-Object {$_}
            }
        }
    }
    $__commandArgs = $__commandArgs | Where-Object {$_ -ne $null}
    if ($__boundParameters["Debug"]){wait-debugger}
    if ( $__boundParameters["Verbose"]) {
         Write-Verbose -Verbose -Message foundry
         $__commandArgs | Write-Verbose -Verbose
    }
    $__handlerInfo = $__outputHandlers[$PSCmdlet.ParameterSetName]
    if (! $__handlerInfo ) {
        $__handlerInfo = $__outputHandlers["Default"] # Guaranteed to be present
    }
    $__handler = $__handlerInfo.Handler
    if ( $PSCmdlet.ShouldProcess("foundry $__commandArgs")) {
    # check for the application and throw if it cannot be found
        if ( -not (Get-Command -ErrorAction Ignore "foundry")) {
          throw "Cannot find executable 'foundry'"
        }
        if ( $__handlerInfo.StreamOutput ) {
            & "foundry" $__commandArgs | & $__handler
        }
        else {
            $result = & "foundry" $__commandArgs
            & $__handler $result
        }
    }
  } # end PROCESS

<#
.SYNOPSIS
Download a Foundry Local model to the local cache.

.DESCRIPTION
Downloads a model to the local cache without running it.

.PARAMETER Model
Name or alias of the model to download.


.PARAMETER Device
Select a model that is valid for the specified device. Valid values: Auto, CPU, GPU, NPU.


.PARAMETER Force
Force download of model even if it already exists in the local cache.


.PARAMETER Token
Access token for authentication.



.EXAMPLE
PS> Save-FoundryLocalModel -Model 'phi-4-mini'

Downloads the phi-4-mini model to the local cache.
Original Command: foundry model download phi-4-mini


.EXAMPLE
PS> Save-FoundryLocalModel -Model 'phi-4-mini' -Device GPU -Force

Downloads the phi-4-mini GPU model, even if it already exists in cache.
Original Command: foundry model download phi-4-mini --device GPU --force


#>
}


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


function Start-FoundryLocalModel
{
[PowerShellCustomFunctionAttribute(RequiresElevation=$False)]
[CmdletBinding(SupportsShouldProcess=$true)]

param(
[Parameter(Mandatory=$true)]
[string]$Model,
[ValidateSet('Auto', 'CPU', 'GPU', 'NPU')]
[Parameter()]
[PSDefaultValue(Value="Auto")]
[string]$Device = "Auto",
[Parameter()]
[PSDefaultValue(Value="600")]
[int]$TimeToLive = "600"
    )

BEGIN {
    $__PARAMETERMAP = @{
         Model = @{
               OriginalName = ''
               OriginalPosition = '0'
               Position = '2147483647'
               ParameterType = 'string'
               ApplyToExecutable = $False
               NoGap = $False
               }
         Device = @{
               OriginalName = '--device'
               OriginalPosition = '0'
               Position = '2147483647'
               ParameterType = 'string'
               ApplyToExecutable = $False
               NoGap = $False
               }
         TimeToLive = @{
               OriginalName = '--ttl'
               OriginalPosition = '0'
               Position = '2147483647'
               ParameterType = 'int'
               ApplyToExecutable = $False
               NoGap = $False
               }
    }

    $__outputHandlers = @{
        Default = @{ StreamOutput = $False; Handler = 'Convert-FoundryLocalLoadOutput' }
    }
}

PROCESS {
    $__boundParameters = $PSBoundParameters
    $__defaultValueParameters = $PSCmdlet.MyInvocation.MyCommand.Parameters.Values.Where({$_.Attributes.Where({$_.TypeId.Name -eq "PSDefaultValueAttribute"})}).Name
    $__defaultValueParameters.Where({ !$__boundParameters["$_"] }).ForEach({$__boundParameters["$_"] = get-variable -value $_})
    $__commandArgs = @()
    $MyInvocation.MyCommand.Parameters.Values.Where({$_.SwitchParameter -and $_.Name -notmatch "Debug|Whatif|Confirm|Verbose" -and ! $__boundParameters[$_.Name]}).ForEach({$__boundParameters[$_.Name] = [switch]::new($false)})
    if ($__boundParameters["Debug"]){wait-debugger}
    $__commandArgs += 'model'
    $__commandArgs += 'load'
    foreach ($paramName in $__boundParameters.Keys|
            Where-Object {!$__PARAMETERMAP[$_].ApplyToExecutable}|
            Sort-Object {$__PARAMETERMAP[$_].OriginalPosition}) {
        $value = $__boundParameters[$paramName]
        $param = $__PARAMETERMAP[$paramName]
        if ($param) {
            if ($value -is [switch]) {
                 if ($value.IsPresent) {
                     if ($param.OriginalName) { $__commandArgs += $param.OriginalName }
                 }
                 elseif ($param.DefaultMissingValue) { $__commandArgs += $param.DefaultMissingValue }
            }
            elseif ( $param.NoGap ) {
                $pFmt = "{0}{1}"
                if($value -match "\s") { $pFmt = "{0}""{1}""" }
                $__commandArgs += $pFmt -f $param.OriginalName, $value
            }
            else {
                if($param.OriginalName) { $__commandArgs += $param.OriginalName }
                $__commandArgs += $value | Foreach-Object {$_}
            }
        }
    }
    $__commandArgs = $__commandArgs | Where-Object {$_ -ne $null}
    if ($__boundParameters["Debug"]){wait-debugger}
    if ( $__boundParameters["Verbose"]) {
         Write-Verbose -Verbose -Message foundry
         $__commandArgs | Write-Verbose -Verbose
    }
    $__handlerInfo = $__outputHandlers[$PSCmdlet.ParameterSetName]
    if (! $__handlerInfo ) {
        $__handlerInfo = $__outputHandlers["Default"] # Guaranteed to be present
    }
    $__handler = $__handlerInfo.Handler
    if ( $PSCmdlet.ShouldProcess("foundry $__commandArgs")) {
    # check for the application and throw if it cannot be found
        if ( -not (Get-Command -ErrorAction Ignore "foundry")) {
          throw "Cannot find executable 'foundry'"
        }
        if ( $__handlerInfo.StreamOutput ) {
            & "foundry" $__commandArgs | & $__handler
        }
        else {
            $result = & "foundry" $__commandArgs
            & $__handler $result
        }
    }
  } # end PROCESS

<#
.SYNOPSIS
Load a model into the Foundry Local service.

.DESCRIPTION
Loads a model into the Foundry Local service.

.PARAMETER Model
Name or alias of the model to load.


.PARAMETER Device
Select a model that is valid for the specified device. Valid values: Auto, CPU, GPU, NPU.


.PARAMETER TimeToLive
Time To Live in seconds. Default is 600 seconds (10 minutes).



.EXAMPLE
PS> Start-FoundryLocalModel -Model 'phi-4-mini'

Loads the phi-4-mini model into the service.
Original Command: foundry model load phi-4-mini


.EXAMPLE
PS> Start-FoundryLocalModel -Model 'phi-4-mini' -Device GPU -TimeToLive 1200

Loads the phi-4-mini GPU model with a 20-minute TTL.
Original Command: foundry model load phi-4-mini --device GPU --ttl 1200


#>
}


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


function Stop-FoundryLocalModel
{
[PowerShellCustomFunctionAttribute(RequiresElevation=$False)]
[CmdletBinding(SupportsShouldProcess=$true)]

param(
[Parameter(Mandatory=$true)]
[string]$Model,
[ValidateSet('Auto', 'CPU', 'GPU', 'NPU')]
[Parameter()]
[PSDefaultValue(Value="Auto")]
[string]$Device = "Auto",
[Parameter()]
[switch]$All,
[Parameter()]
[switch]$Force
    )

BEGIN {
    $__PARAMETERMAP = @{
         Model = @{
               OriginalName = ''
               OriginalPosition = '0'
               Position = '2147483647'
               ParameterType = 'string'
               ApplyToExecutable = $False
               NoGap = $False
               }
         Device = @{
               OriginalName = '--device'
               OriginalPosition = '0'
               Position = '2147483647'
               ParameterType = 'string'
               ApplyToExecutable = $False
               NoGap = $False
               }
         All = @{
               OriginalName = '--all'
               OriginalPosition = '0'
               Position = '2147483647'
               ParameterType = 'switch'
               ApplyToExecutable = $False
               NoGap = $False
               }
         Force = @{
               OriginalName = '--force'
               OriginalPosition = '0'
               Position = '2147483647'
               ParameterType = 'switch'
               ApplyToExecutable = $False
               NoGap = $False
               }
    }

    $__outputHandlers = @{
        Default = @{ StreamOutput = $False; Handler = 'Convert-FoundryLocalUnloadOutput' }
    }
}

PROCESS {
    $__boundParameters = $PSBoundParameters
    $__defaultValueParameters = $PSCmdlet.MyInvocation.MyCommand.Parameters.Values.Where({$_.Attributes.Where({$_.TypeId.Name -eq "PSDefaultValueAttribute"})}).Name
    $__defaultValueParameters.Where({ !$__boundParameters["$_"] }).ForEach({$__boundParameters["$_"] = get-variable -value $_})
    $__commandArgs = @()
    $MyInvocation.MyCommand.Parameters.Values.Where({$_.SwitchParameter -and $_.Name -notmatch "Debug|Whatif|Confirm|Verbose" -and ! $__boundParameters[$_.Name]}).ForEach({$__boundParameters[$_.Name] = [switch]::new($false)})
    if ($__boundParameters["Debug"]){wait-debugger}
    $__commandArgs += 'model'
    $__commandArgs += 'unload'
    foreach ($paramName in $__boundParameters.Keys|
            Where-Object {!$__PARAMETERMAP[$_].ApplyToExecutable}|
            Sort-Object {$__PARAMETERMAP[$_].OriginalPosition}) {
        $value = $__boundParameters[$paramName]
        $param = $__PARAMETERMAP[$paramName]
        if ($param) {
            if ($value -is [switch]) {
                 if ($value.IsPresent) {
                     if ($param.OriginalName) { $__commandArgs += $param.OriginalName }
                 }
                 elseif ($param.DefaultMissingValue) { $__commandArgs += $param.DefaultMissingValue }
            }
            elseif ( $param.NoGap ) {
                $pFmt = "{0}{1}"
                if($value -match "\s") { $pFmt = "{0}""{1}""" }
                $__commandArgs += $pFmt -f $param.OriginalName, $value
            }
            else {
                if($param.OriginalName) { $__commandArgs += $param.OriginalName }
                $__commandArgs += $value | Foreach-Object {$_}
            }
        }
    }
    $__commandArgs = $__commandArgs | Where-Object {$_ -ne $null}
    if ($__boundParameters["Debug"]){wait-debugger}
    if ( $__boundParameters["Verbose"]) {
         Write-Verbose -Verbose -Message foundry
         $__commandArgs | Write-Verbose -Verbose
    }
    $__handlerInfo = $__outputHandlers[$PSCmdlet.ParameterSetName]
    if (! $__handlerInfo ) {
        $__handlerInfo = $__outputHandlers["Default"] # Guaranteed to be present
    }
    $__handler = $__handlerInfo.Handler
    if ( $PSCmdlet.ShouldProcess("foundry $__commandArgs")) {
    # check for the application and throw if it cannot be found
        if ( -not (Get-Command -ErrorAction Ignore "foundry")) {
          throw "Cannot find executable 'foundry'"
        }
        if ( $__handlerInfo.StreamOutput ) {
            & "foundry" $__commandArgs | & $__handler
        }
        else {
            $result = & "foundry" $__commandArgs
            & $__handler $result
        }
    }
  } # end PROCESS

<#
.SYNOPSIS
Unload a model from the Foundry Local service.

.DESCRIPTION
Unloads a model from the Foundry Local service.

.PARAMETER Model
Name or alias of the model to unload.


.PARAMETER Device
Select a model that is valid for the specified device. Valid values: Auto, CPU, GPU, NPU.


.PARAMETER All
Unload all models matching the specified alias instead of just the best match.


.PARAMETER Force
Force the unloading.



.EXAMPLE
PS> Stop-FoundryLocalModel -Model 'phi-4-mini'

Unloads the phi-4-mini model from the service.
Original Command: foundry model unload phi-4-mini


.EXAMPLE
PS> Stop-FoundryLocalModel -Model 'phi-4-mini' -All

Unloads all models matching the phi-4-mini alias.
Original Command: foundry model unload phi-4-mini --all


#>
}


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
    # Check for "not running" first to avoid false positive from "running" substring
    if ($outputText -match 'not running|stopped') {
        $serviceStatus.IsRunning = $false
    }
    elseif ($outputText -match 'Started|is running') {
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

    return $serviceStatus
}


function Get-FoundryLocalService
{
[PowerShellCustomFunctionAttribute(RequiresElevation=$False)]
[CmdletBinding()]

param(    )

BEGIN {
    $__PARAMETERMAP = @{}
    $__outputHandlers = @{
        Default = @{ StreamOutput = $False; Handler = 'Convert-FoundryLocalServiceStatusOutput' }
    }
}

PROCESS {
    $__boundParameters = $PSBoundParameters
    $__defaultValueParameters = $PSCmdlet.MyInvocation.MyCommand.Parameters.Values.Where({$_.Attributes.Where({$_.TypeId.Name -eq "PSDefaultValueAttribute"})}).Name
    $__defaultValueParameters.Where({ !$__boundParameters["$_"] }).ForEach({$__boundParameters["$_"] = get-variable -value $_})
    $__commandArgs = @()
    $MyInvocation.MyCommand.Parameters.Values.Where({$_.SwitchParameter -and $_.Name -notmatch "Debug|Whatif|Confirm|Verbose" -and ! $__boundParameters[$_.Name]}).ForEach({$__boundParameters[$_.Name] = [switch]::new($false)})
    if ($__boundParameters["Debug"]){wait-debugger}
    $__commandArgs += 'service'
    $__commandArgs += 'status'
    foreach ($paramName in $__boundParameters.Keys|
            Where-Object {!$__PARAMETERMAP[$_].ApplyToExecutable}|
            Sort-Object {$__PARAMETERMAP[$_].OriginalPosition}) {
        $value = $__boundParameters[$paramName]
        $param = $__PARAMETERMAP[$paramName]
        if ($param) {
            if ($value -is [switch]) {
                 if ($value.IsPresent) {
                     if ($param.OriginalName) { $__commandArgs += $param.OriginalName }
                 }
                 elseif ($param.DefaultMissingValue) { $__commandArgs += $param.DefaultMissingValue }
            }
            elseif ( $param.NoGap ) {
                $pFmt = "{0}{1}"
                if($value -match "\s") { $pFmt = "{0}""{1}""" }
                $__commandArgs += $pFmt -f $param.OriginalName, $value
            }
            else {
                if($param.OriginalName) { $__commandArgs += $param.OriginalName }
                $__commandArgs += $value | Foreach-Object {$_}
            }
        }
    }
    $__commandArgs = $__commandArgs | Where-Object {$_ -ne $null}
    if ($__boundParameters["Debug"]){wait-debugger}
    if ( $__boundParameters["Verbose"]) {
         Write-Verbose -Verbose -Message foundry
         $__commandArgs | Write-Verbose -Verbose
    }
    $__handlerInfo = $__outputHandlers[$PSCmdlet.ParameterSetName]
    if (! $__handlerInfo ) {
        $__handlerInfo = $__outputHandlers["Default"] # Guaranteed to be present
    }
    $__handler = $__handlerInfo.Handler
    if ( $PSCmdlet.ShouldProcess("foundry $__commandArgs")) {
    # check for the application and throw if it cannot be found
        if ( -not (Get-Command -ErrorAction Ignore "foundry")) {
          throw "Cannot find executable 'foundry'"
        }
        if ( $__handlerInfo.StreamOutput ) {
            & "foundry" $__commandArgs | & $__handler
        }
        else {
            $result = & "foundry" $__commandArgs
            & $__handler $result
        }
    }
  } # end PROCESS

<#
.SYNOPSIS
Get the status of the Foundry Local service.

.DESCRIPTION
Gets the current status of the Foundry Local service.

.EXAMPLE
PS> Get-FoundryLocalService

Gets the current status of the Foundry Local service.
Original Command: foundry service status


#>
}


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


function Get-FoundryLocalServiceModel
{
[PowerShellCustomFunctionAttribute(RequiresElevation=$False)]
[CmdletBinding()]

param(    )

BEGIN {
    $__PARAMETERMAP = @{}
    $__outputHandlers = @{
        Default = @{ StreamOutput = $False; Handler = 'Convert-FoundryLocalServicePsOutput' }
    }
}

PROCESS {
    $__boundParameters = $PSBoundParameters
    $__defaultValueParameters = $PSCmdlet.MyInvocation.MyCommand.Parameters.Values.Where({$_.Attributes.Where({$_.TypeId.Name -eq "PSDefaultValueAttribute"})}).Name
    $__defaultValueParameters.Where({ !$__boundParameters["$_"] }).ForEach({$__boundParameters["$_"] = get-variable -value $_})
    $__commandArgs = @()
    $MyInvocation.MyCommand.Parameters.Values.Where({$_.SwitchParameter -and $_.Name -notmatch "Debug|Whatif|Confirm|Verbose" -and ! $__boundParameters[$_.Name]}).ForEach({$__boundParameters[$_.Name] = [switch]::new($false)})
    if ($__boundParameters["Debug"]){wait-debugger}
    $__commandArgs += 'service'
    $__commandArgs += 'ps'
    foreach ($paramName in $__boundParameters.Keys|
            Where-Object {!$__PARAMETERMAP[$_].ApplyToExecutable}|
            Sort-Object {$__PARAMETERMAP[$_].OriginalPosition}) {
        $value = $__boundParameters[$paramName]
        $param = $__PARAMETERMAP[$paramName]
        if ($param) {
            if ($value -is [switch]) {
                 if ($value.IsPresent) {
                     if ($param.OriginalName) { $__commandArgs += $param.OriginalName }
                 }
                 elseif ($param.DefaultMissingValue) { $__commandArgs += $param.DefaultMissingValue }
            }
            elseif ( $param.NoGap ) {
                $pFmt = "{0}{1}"
                if($value -match "\s") { $pFmt = "{0}""{1}""" }
                $__commandArgs += $pFmt -f $param.OriginalName, $value
            }
            else {
                if($param.OriginalName) { $__commandArgs += $param.OriginalName }
                $__commandArgs += $value | Foreach-Object {$_}
            }
        }
    }
    $__commandArgs = $__commandArgs | Where-Object {$_ -ne $null}
    if ($__boundParameters["Debug"]){wait-debugger}
    if ( $__boundParameters["Verbose"]) {
         Write-Verbose -Verbose -Message foundry
         $__commandArgs | Write-Verbose -Verbose
    }
    $__handlerInfo = $__outputHandlers[$PSCmdlet.ParameterSetName]
    if (! $__handlerInfo ) {
        $__handlerInfo = $__outputHandlers["Default"] # Guaranteed to be present
    }
    $__handler = $__handlerInfo.Handler
    if ( $PSCmdlet.ShouldProcess("foundry $__commandArgs")) {
    # check for the application and throw if it cannot be found
        if ( -not (Get-Command -ErrorAction Ignore "foundry")) {
          throw "Cannot find executable 'foundry'"
        }
        if ( $__handlerInfo.StreamOutput ) {
            & "foundry" $__commandArgs | & $__handler
        }
        else {
            $result = & "foundry" $__commandArgs
            & $__handler $result
        }
    }
  } # end PROCESS

<#
.SYNOPSIS
Get the list of models loaded in the Foundry Local service.

.DESCRIPTION
Lists all models currently loaded in the Foundry Local service.

.EXAMPLE
PS> Get-FoundryLocalServiceModel

Lists all models currently loaded in the service.
Original Command: foundry service ps


#>
}


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


function Start-FoundryLocalService
{
[PowerShellCustomFunctionAttribute(RequiresElevation=$False)]
[CmdletBinding(SupportsShouldProcess=$true)]

param(    )

BEGIN {
    $__PARAMETERMAP = @{}
    $__outputHandlers = @{
        Default = @{ StreamOutput = $False; Handler = 'Convert-FoundryLocalServiceStartOutput' }
    }
}

PROCESS {
    $__boundParameters = $PSBoundParameters
    $__defaultValueParameters = $PSCmdlet.MyInvocation.MyCommand.Parameters.Values.Where({$_.Attributes.Where({$_.TypeId.Name -eq "PSDefaultValueAttribute"})}).Name
    $__defaultValueParameters.Where({ !$__boundParameters["$_"] }).ForEach({$__boundParameters["$_"] = get-variable -value $_})
    $__commandArgs = @()
    $MyInvocation.MyCommand.Parameters.Values.Where({$_.SwitchParameter -and $_.Name -notmatch "Debug|Whatif|Confirm|Verbose" -and ! $__boundParameters[$_.Name]}).ForEach({$__boundParameters[$_.Name] = [switch]::new($false)})
    if ($__boundParameters["Debug"]){wait-debugger}
    $__commandArgs += 'service'
    $__commandArgs += 'start'
    foreach ($paramName in $__boundParameters.Keys|
            Where-Object {!$__PARAMETERMAP[$_].ApplyToExecutable}|
            Sort-Object {$__PARAMETERMAP[$_].OriginalPosition}) {
        $value = $__boundParameters[$paramName]
        $param = $__PARAMETERMAP[$paramName]
        if ($param) {
            if ($value -is [switch]) {
                 if ($value.IsPresent) {
                     if ($param.OriginalName) { $__commandArgs += $param.OriginalName }
                 }
                 elseif ($param.DefaultMissingValue) { $__commandArgs += $param.DefaultMissingValue }
            }
            elseif ( $param.NoGap ) {
                $pFmt = "{0}{1}"
                if($value -match "\s") { $pFmt = "{0}""{1}""" }
                $__commandArgs += $pFmt -f $param.OriginalName, $value
            }
            else {
                if($param.OriginalName) { $__commandArgs += $param.OriginalName }
                $__commandArgs += $value | Foreach-Object {$_}
            }
        }
    }
    $__commandArgs = $__commandArgs | Where-Object {$_ -ne $null}
    if ($__boundParameters["Debug"]){wait-debugger}
    if ( $__boundParameters["Verbose"]) {
         Write-Verbose -Verbose -Message foundry
         $__commandArgs | Write-Verbose -Verbose
    }
    $__handlerInfo = $__outputHandlers[$PSCmdlet.ParameterSetName]
    if (! $__handlerInfo ) {
        $__handlerInfo = $__outputHandlers["Default"] # Guaranteed to be present
    }
    $__handler = $__handlerInfo.Handler
    if ( $PSCmdlet.ShouldProcess("foundry $__commandArgs")) {
    # check for the application and throw if it cannot be found
        if ( -not (Get-Command -ErrorAction Ignore "foundry")) {
          throw "Cannot find executable 'foundry'"
        }
        if ( $__handlerInfo.StreamOutput ) {
            & "foundry" $__commandArgs | & $__handler
        }
        else {
            $result = & "foundry" $__commandArgs
            & $__handler $result
        }
    }
  } # end PROCESS

<#
.SYNOPSIS
Start the Foundry Local service.

.DESCRIPTION
Starts the Foundry Local service.

.EXAMPLE
PS> Start-FoundryLocalService

Starts the Foundry Local service.
Original Command: foundry service start


#>
}


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


function Stop-FoundryLocalService
{
[PowerShellCustomFunctionAttribute(RequiresElevation=$False)]
[CmdletBinding(SupportsShouldProcess=$true)]

param(    )

BEGIN {
    $__PARAMETERMAP = @{}
    $__outputHandlers = @{
        Default = @{ StreamOutput = $False; Handler = 'Convert-FoundryLocalServiceStopOutput' }
    }
}

PROCESS {
    $__boundParameters = $PSBoundParameters
    $__defaultValueParameters = $PSCmdlet.MyInvocation.MyCommand.Parameters.Values.Where({$_.Attributes.Where({$_.TypeId.Name -eq "PSDefaultValueAttribute"})}).Name
    $__defaultValueParameters.Where({ !$__boundParameters["$_"] }).ForEach({$__boundParameters["$_"] = get-variable -value $_})
    $__commandArgs = @()
    $MyInvocation.MyCommand.Parameters.Values.Where({$_.SwitchParameter -and $_.Name -notmatch "Debug|Whatif|Confirm|Verbose" -and ! $__boundParameters[$_.Name]}).ForEach({$__boundParameters[$_.Name] = [switch]::new($false)})
    if ($__boundParameters["Debug"]){wait-debugger}
    $__commandArgs += 'service'
    $__commandArgs += 'stop'
    foreach ($paramName in $__boundParameters.Keys|
            Where-Object {!$__PARAMETERMAP[$_].ApplyToExecutable}|
            Sort-Object {$__PARAMETERMAP[$_].OriginalPosition}) {
        $value = $__boundParameters[$paramName]
        $param = $__PARAMETERMAP[$paramName]
        if ($param) {
            if ($value -is [switch]) {
                 if ($value.IsPresent) {
                     if ($param.OriginalName) { $__commandArgs += $param.OriginalName }
                 }
                 elseif ($param.DefaultMissingValue) { $__commandArgs += $param.DefaultMissingValue }
            }
            elseif ( $param.NoGap ) {
                $pFmt = "{0}{1}"
                if($value -match "\s") { $pFmt = "{0}""{1}""" }
                $__commandArgs += $pFmt -f $param.OriginalName, $value
            }
            else {
                if($param.OriginalName) { $__commandArgs += $param.OriginalName }
                $__commandArgs += $value | Foreach-Object {$_}
            }
        }
    }
    $__commandArgs = $__commandArgs | Where-Object {$_ -ne $null}
    if ($__boundParameters["Debug"]){wait-debugger}
    if ( $__boundParameters["Verbose"]) {
         Write-Verbose -Verbose -Message foundry
         $__commandArgs | Write-Verbose -Verbose
    }
    $__handlerInfo = $__outputHandlers[$PSCmdlet.ParameterSetName]
    if (! $__handlerInfo ) {
        $__handlerInfo = $__outputHandlers["Default"] # Guaranteed to be present
    }
    $__handler = $__handlerInfo.Handler
    if ( $PSCmdlet.ShouldProcess("foundry $__commandArgs")) {
    # check for the application and throw if it cannot be found
        if ( -not (Get-Command -ErrorAction Ignore "foundry")) {
          throw "Cannot find executable 'foundry'"
        }
        if ( $__handlerInfo.StreamOutput ) {
            & "foundry" $__commandArgs | & $__handler
        }
        else {
            $result = & "foundry" $__commandArgs
            & $__handler $result
        }
    }
  } # end PROCESS

<#
.SYNOPSIS
Stop the Foundry Local service.

.DESCRIPTION
Stops the Foundry Local service.

.EXAMPLE
PS> Stop-FoundryLocalService

Stops the Foundry Local service.
Original Command: foundry service stop


#>
}


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


function Restart-FoundryLocalService
{
[PowerShellCustomFunctionAttribute(RequiresElevation=$False)]
[CmdletBinding(SupportsShouldProcess=$true)]

param(    )

BEGIN {
    $__PARAMETERMAP = @{}
    $__outputHandlers = @{
        Default = @{ StreamOutput = $False; Handler = 'Convert-FoundryLocalServiceRestartOutput' }
    }
}

PROCESS {
    $__boundParameters = $PSBoundParameters
    $__defaultValueParameters = $PSCmdlet.MyInvocation.MyCommand.Parameters.Values.Where({$_.Attributes.Where({$_.TypeId.Name -eq "PSDefaultValueAttribute"})}).Name
    $__defaultValueParameters.Where({ !$__boundParameters["$_"] }).ForEach({$__boundParameters["$_"] = get-variable -value $_})
    $__commandArgs = @()
    $MyInvocation.MyCommand.Parameters.Values.Where({$_.SwitchParameter -and $_.Name -notmatch "Debug|Whatif|Confirm|Verbose" -and ! $__boundParameters[$_.Name]}).ForEach({$__boundParameters[$_.Name] = [switch]::new($false)})
    if ($__boundParameters["Debug"]){wait-debugger}
    $__commandArgs += 'service'
    $__commandArgs += 'restart'
    foreach ($paramName in $__boundParameters.Keys|
            Where-Object {!$__PARAMETERMAP[$_].ApplyToExecutable}|
            Sort-Object {$__PARAMETERMAP[$_].OriginalPosition}) {
        $value = $__boundParameters[$paramName]
        $param = $__PARAMETERMAP[$paramName]
        if ($param) {
            if ($value -is [switch]) {
                 if ($value.IsPresent) {
                     if ($param.OriginalName) { $__commandArgs += $param.OriginalName }
                 }
                 elseif ($param.DefaultMissingValue) { $__commandArgs += $param.DefaultMissingValue }
            }
            elseif ( $param.NoGap ) {
                $pFmt = "{0}{1}"
                if($value -match "\s") { $pFmt = "{0}""{1}""" }
                $__commandArgs += $pFmt -f $param.OriginalName, $value
            }
            else {
                if($param.OriginalName) { $__commandArgs += $param.OriginalName }
                $__commandArgs += $value | Foreach-Object {$_}
            }
        }
    }
    $__commandArgs = $__commandArgs | Where-Object {$_ -ne $null}
    if ($__boundParameters["Debug"]){wait-debugger}
    if ( $__boundParameters["Verbose"]) {
         Write-Verbose -Verbose -Message foundry
         $__commandArgs | Write-Verbose -Verbose
    }
    $__handlerInfo = $__outputHandlers[$PSCmdlet.ParameterSetName]
    if (! $__handlerInfo ) {
        $__handlerInfo = $__outputHandlers["Default"] # Guaranteed to be present
    }
    $__handler = $__handlerInfo.Handler
    if ( $PSCmdlet.ShouldProcess("foundry $__commandArgs")) {
    # check for the application and throw if it cannot be found
        if ( -not (Get-Command -ErrorAction Ignore "foundry")) {
          throw "Cannot find executable 'foundry'"
        }
        if ( $__handlerInfo.StreamOutput ) {
            & "foundry" $__commandArgs | & $__handler
        }
        else {
            $result = & "foundry" $__commandArgs
            & $__handler $result
        }
    }
  } # end PROCESS

<#
.SYNOPSIS
Restart the Foundry Local service.

.DESCRIPTION
Restarts the Foundry Local service.

.EXAMPLE
PS> Restart-FoundryLocalService

Restarts the Foundry Local service.
Original Command: foundry service restart


#>
}


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
    $currentRow = $null

    foreach ($line in $lines) {
        $trimmedLine = $line.Trim()

        # Skip empty lines
        if ([string]::IsNullOrWhiteSpace($trimmedLine)) {
            continue
        }

        # Skip informational line
        if ($trimmedLine -match 'Models cached') {
            continue
        }

        # Detect header line (Alias / Model ID on one line)
        if ($trimmedLine -match '^\s*Alias\s+Model ID\s*$') {
            $inDataSection = $true
            $currentRow = $null
            continue
        }

        if (-not $inDataSection) {
            continue
        }

        # Once in data section, assemble logical rows to undo console wrapping.
        # A new row starts when we see an alias (optionally prefixed with an icon).
        # Use an explicit ASCII character class so that garbled emoji bytes are not
        # treated as part of the alias.
        if ($trimmedLine -match '^[^A-Za-z0-9_.-]*(?<alias>[A-Za-z0-9_.-]+)\b' -and $trimmedLine -notmatch 'Alias|Model ID') {
            # Flush previous row if present
            if ($currentRow) {
                if ($currentRow -match '^[^A-Za-z0-9_.-]*(?<ra>[A-Za-z0-9_.-]+)\s+(?<rm>.+)$' -and $currentRow -notmatch 'Cache directory') {
                    [PSCustomObject]@{
                        PSTypeName = 'psfoundrylocal.CachedModel'
                        Alias      = $Matches['ra'].Trim()
                        ModelId    = $Matches['rm'].Trim()
                    }
                }
            }

            $currentRow = $trimmedLine
            continue
        }

        # Continuation of the current row (wrapped model id line)
        if ($currentRow) {
            $currentRow = "$currentRow $trimmedLine"
        }
    }

    # Flush the final row
    if ($currentRow -and $currentRow -match '^[^A-Za-z0-9_.-]*(?<fa>[A-Za-z0-9_.-]+)\s+(?<fm>.+)$' -and $currentRow -notmatch 'Cache directory') {
        [PSCustomObject]@{
            PSTypeName = 'psfoundrylocal.CachedModel'
            Alias      = $Matches['fa'].Trim()
            ModelId    = $Matches['fm'].Trim()
        }
    }
}


function Get-FoundryLocalCache
{
[PowerShellCustomFunctionAttribute(RequiresElevation=$False)]
[CmdletBinding()]

param(    )

BEGIN {
    $__PARAMETERMAP = @{}
    $__outputHandlers = @{
        Default = @{ StreamOutput = $False; Handler = 'Convert-FoundryLocalCacheListOutput' }
    }
}

PROCESS {
    $__boundParameters = $PSBoundParameters
    $__defaultValueParameters = $PSCmdlet.MyInvocation.MyCommand.Parameters.Values.Where({$_.Attributes.Where({$_.TypeId.Name -eq "PSDefaultValueAttribute"})}).Name
    $__defaultValueParameters.Where({ !$__boundParameters["$_"] }).ForEach({$__boundParameters["$_"] = get-variable -value $_})
    $__commandArgs = @()
    $MyInvocation.MyCommand.Parameters.Values.Where({$_.SwitchParameter -and $_.Name -notmatch "Debug|Whatif|Confirm|Verbose" -and ! $__boundParameters[$_.Name]}).ForEach({$__boundParameters[$_.Name] = [switch]::new($false)})
    if ($__boundParameters["Debug"]){wait-debugger}
    $__commandArgs += 'cache'
    $__commandArgs += 'list'
    foreach ($paramName in $__boundParameters.Keys|
            Where-Object {!$__PARAMETERMAP[$_].ApplyToExecutable}|
            Sort-Object {$__PARAMETERMAP[$_].OriginalPosition}) {
        $value = $__boundParameters[$paramName]
        $param = $__PARAMETERMAP[$paramName]
        if ($param) {
            if ($value -is [switch]) {
                 if ($value.IsPresent) {
                     if ($param.OriginalName) { $__commandArgs += $param.OriginalName }
                 }
                 elseif ($param.DefaultMissingValue) { $__commandArgs += $param.DefaultMissingValue }
            }
            elseif ( $param.NoGap ) {
                $pFmt = "{0}{1}"
                if($value -match "\s") { $pFmt = "{0}""{1}""" }
                $__commandArgs += $pFmt -f $param.OriginalName, $value
            }
            else {
                if($param.OriginalName) { $__commandArgs += $param.OriginalName }
                $__commandArgs += $value | Foreach-Object {$_}
            }
        }
    }
    $__commandArgs = $__commandArgs | Where-Object {$_ -ne $null}
    if ($__boundParameters["Debug"]){wait-debugger}
    if ( $__boundParameters["Verbose"]) {
         Write-Verbose -Verbose -Message foundry
         $__commandArgs | Write-Verbose -Verbose
    }
    $__handlerInfo = $__outputHandlers[$PSCmdlet.ParameterSetName]
    if (! $__handlerInfo ) {
        $__handlerInfo = $__outputHandlers["Default"] # Guaranteed to be present
    }
    $__handler = $__handlerInfo.Handler
    if ( $PSCmdlet.ShouldProcess("foundry $__commandArgs")) {
    # check for the application and throw if it cannot be found
        if ( -not (Get-Command -ErrorAction Ignore "foundry")) {
          throw "Cannot find executable 'foundry'"
        }
        if ( $__handlerInfo.StreamOutput ) {
            & "foundry" $__commandArgs | & $__handler
        }
        else {
            $result = & "foundry" $__commandArgs
            & $__handler $result
        }
    }
  } # end PROCESS

<#
.SYNOPSIS
Get the list of cached Foundry Local models.

.DESCRIPTION
Lists all models stored in the local cache.

.EXAMPLE
PS> Get-FoundryLocalCache

Lists all models in the local cache.
Original Command: foundry cache list


#>
}


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


function Get-FoundryLocalCacheLocation
{
[PowerShellCustomFunctionAttribute(RequiresElevation=$False)]
[CmdletBinding()]

param(    )

BEGIN {
    $__PARAMETERMAP = @{}
    $__outputHandlers = @{
        Default = @{ StreamOutput = $False; Handler = 'Convert-FoundryLocalCacheLocationOutput' }
    }
}

PROCESS {
    $__boundParameters = $PSBoundParameters
    $__defaultValueParameters = $PSCmdlet.MyInvocation.MyCommand.Parameters.Values.Where({$_.Attributes.Where({$_.TypeId.Name -eq "PSDefaultValueAttribute"})}).Name
    $__defaultValueParameters.Where({ !$__boundParameters["$_"] }).ForEach({$__boundParameters["$_"] = get-variable -value $_})
    $__commandArgs = @()
    $MyInvocation.MyCommand.Parameters.Values.Where({$_.SwitchParameter -and $_.Name -notmatch "Debug|Whatif|Confirm|Verbose" -and ! $__boundParameters[$_.Name]}).ForEach({$__boundParameters[$_.Name] = [switch]::new($false)})
    if ($__boundParameters["Debug"]){wait-debugger}
    $__commandArgs += 'cache'
    $__commandArgs += 'location'
    foreach ($paramName in $__boundParameters.Keys|
            Where-Object {!$__PARAMETERMAP[$_].ApplyToExecutable}|
            Sort-Object {$__PARAMETERMAP[$_].OriginalPosition}) {
        $value = $__boundParameters[$paramName]
        $param = $__PARAMETERMAP[$paramName]
        if ($param) {
            if ($value -is [switch]) {
                 if ($value.IsPresent) {
                     if ($param.OriginalName) { $__commandArgs += $param.OriginalName }
                 }
                 elseif ($param.DefaultMissingValue) { $__commandArgs += $param.DefaultMissingValue }
            }
            elseif ( $param.NoGap ) {
                $pFmt = "{0}{1}"
                if($value -match "\s") { $pFmt = "{0}""{1}""" }
                $__commandArgs += $pFmt -f $param.OriginalName, $value
            }
            else {
                if($param.OriginalName) { $__commandArgs += $param.OriginalName }
                $__commandArgs += $value | Foreach-Object {$_}
            }
        }
    }
    $__commandArgs = $__commandArgs | Where-Object {$_ -ne $null}
    if ($__boundParameters["Debug"]){wait-debugger}
    if ( $__boundParameters["Verbose"]) {
         Write-Verbose -Verbose -Message foundry
         $__commandArgs | Write-Verbose -Verbose
    }
    $__handlerInfo = $__outputHandlers[$PSCmdlet.ParameterSetName]
    if (! $__handlerInfo ) {
        $__handlerInfo = $__outputHandlers["Default"] # Guaranteed to be present
    }
    $__handler = $__handlerInfo.Handler
    if ( $PSCmdlet.ShouldProcess("foundry $__commandArgs")) {
    # check for the application and throw if it cannot be found
        if ( -not (Get-Command -ErrorAction Ignore "foundry")) {
          throw "Cannot find executable 'foundry'"
        }
        if ( $__handlerInfo.StreamOutput ) {
            & "foundry" $__commandArgs | & $__handler
        }
        else {
            $result = & "foundry" $__commandArgs
            & $__handler $result
        }
    }
  } # end PROCESS

<#
.SYNOPSIS
Get the Foundry Local cache directory location.

.DESCRIPTION
Gets the current cache directory path for Foundry Local models.

.EXAMPLE
PS> Get-FoundryLocalCacheLocation

Gets the current cache directory path.
Original Command: foundry cache location


#>
}


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


function Set-FoundryLocalCacheLocation
{
[PowerShellCustomFunctionAttribute(RequiresElevation=$False)]
[CmdletBinding(SupportsShouldProcess=$true)]

param(
[Parameter(Mandatory=$true)]
[string]$Path
    )

BEGIN {
    $__PARAMETERMAP = @{
         Path = @{
               OriginalName = ''
               OriginalPosition = '0'
               Position = '2147483647'
               ParameterType = 'string'
               ApplyToExecutable = $False
               NoGap = $False
               }
    }

    $__outputHandlers = @{
        Default = @{ StreamOutput = $False; Handler = 'Convert-FoundryLocalCacheCdOutput' }
    }
}

PROCESS {
    $__boundParameters = $PSBoundParameters
    $__defaultValueParameters = $PSCmdlet.MyInvocation.MyCommand.Parameters.Values.Where({$_.Attributes.Where({$_.TypeId.Name -eq "PSDefaultValueAttribute"})}).Name
    $__defaultValueParameters.Where({ !$__boundParameters["$_"] }).ForEach({$__boundParameters["$_"] = get-variable -value $_})
    $__commandArgs = @()
    $MyInvocation.MyCommand.Parameters.Values.Where({$_.SwitchParameter -and $_.Name -notmatch "Debug|Whatif|Confirm|Verbose" -and ! $__boundParameters[$_.Name]}).ForEach({$__boundParameters[$_.Name] = [switch]::new($false)})
    if ($__boundParameters["Debug"]){wait-debugger}
    $__commandArgs += 'cache'
    $__commandArgs += 'cd'
    foreach ($paramName in $__boundParameters.Keys|
            Where-Object {!$__PARAMETERMAP[$_].ApplyToExecutable}|
            Sort-Object {$__PARAMETERMAP[$_].OriginalPosition}) {
        $value = $__boundParameters[$paramName]
        $param = $__PARAMETERMAP[$paramName]
        if ($param) {
            if ($value -is [switch]) {
                 if ($value.IsPresent) {
                     if ($param.OriginalName) { $__commandArgs += $param.OriginalName }
                 }
                 elseif ($param.DefaultMissingValue) { $__commandArgs += $param.DefaultMissingValue }
            }
            elseif ( $param.NoGap ) {
                $pFmt = "{0}{1}"
                if($value -match "\s") { $pFmt = "{0}""{1}""" }
                $__commandArgs += $pFmt -f $param.OriginalName, $value
            }
            else {
                if($param.OriginalName) { $__commandArgs += $param.OriginalName }
                $__commandArgs += $value | Foreach-Object {$_}
            }
        }
    }
    $__commandArgs = $__commandArgs | Where-Object {$_ -ne $null}
    if ($__boundParameters["Debug"]){wait-debugger}
    if ( $__boundParameters["Verbose"]) {
         Write-Verbose -Verbose -Message foundry
         $__commandArgs | Write-Verbose -Verbose
    }
    $__handlerInfo = $__outputHandlers[$PSCmdlet.ParameterSetName]
    if (! $__handlerInfo ) {
        $__handlerInfo = $__outputHandlers["Default"] # Guaranteed to be present
    }
    $__handler = $__handlerInfo.Handler
    if ( $PSCmdlet.ShouldProcess("foundry $__commandArgs")) {
    # check for the application and throw if it cannot be found
        if ( -not (Get-Command -ErrorAction Ignore "foundry")) {
          throw "Cannot find executable 'foundry'"
        }
        if ( $__handlerInfo.StreamOutput ) {
            & "foundry" $__commandArgs | & $__handler
        }
        else {
            $result = & "foundry" $__commandArgs
            & $__handler $result
        }
    }
  } # end PROCESS

<#
.SYNOPSIS
Set the Foundry Local cache directory location.

.DESCRIPTION
Changes the cache directory path for Foundry Local models.

.PARAMETER Path
The new model cache directory path.



.EXAMPLE
PS> Set-FoundryLocalCacheLocation -Path 'D:\FoundryCache'

Changes the cache directory to D:\FoundryCache.
Original Command: foundry cache cd D:\FoundryCache


#>
}


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


function Remove-FoundryLocalCachedModel
{
[PowerShellCustomFunctionAttribute(RequiresElevation=$False)]
[CmdletBinding(SupportsShouldProcess=$true)]

param(
[Parameter(Mandatory=$true)]
[string]$Model,
[ValidateSet('Auto', 'CPU', 'GPU', 'NPU')]
[Parameter()]
[PSDefaultValue(Value="Auto")]
[string]$Device = "Auto",
[Parameter()]
[switch]$All,
[Parameter()]
[switch]$Yes
    )

BEGIN {
    $__PARAMETERMAP = @{
         Model = @{
               OriginalName = ''
               OriginalPosition = '0'
               Position = '2147483647'
               ParameterType = 'string'
               ApplyToExecutable = $False
               NoGap = $False
               }
         Device = @{
               OriginalName = '--device'
               OriginalPosition = '0'
               Position = '2147483647'
               ParameterType = 'string'
               ApplyToExecutable = $False
               NoGap = $False
               }
         All = @{
               OriginalName = '--all'
               OriginalPosition = '0'
               Position = '2147483647'
               ParameterType = 'switch'
               ApplyToExecutable = $False
               NoGap = $False
               }
         Yes = @{
               OriginalName = '--yes'
               OriginalPosition = '0'
               Position = '2147483647'
               ParameterType = 'switch'
               ApplyToExecutable = $False
               NoGap = $False
               }
    }

    $__outputHandlers = @{
        Default = @{ StreamOutput = $False; Handler = 'Convert-FoundryLocalCacheRemoveOutput' }
    }
}

PROCESS {
    $__boundParameters = $PSBoundParameters
    $__defaultValueParameters = $PSCmdlet.MyInvocation.MyCommand.Parameters.Values.Where({$_.Attributes.Where({$_.TypeId.Name -eq "PSDefaultValueAttribute"})}).Name
    $__defaultValueParameters.Where({ !$__boundParameters["$_"] }).ForEach({$__boundParameters["$_"] = get-variable -value $_})
    $__commandArgs = @()
    $MyInvocation.MyCommand.Parameters.Values.Where({$_.SwitchParameter -and $_.Name -notmatch "Debug|Whatif|Confirm|Verbose" -and ! $__boundParameters[$_.Name]}).ForEach({$__boundParameters[$_.Name] = [switch]::new($false)})
    if ($__boundParameters["Debug"]){wait-debugger}
    $__commandArgs += 'cache'
    $__commandArgs += 'remove'
    foreach ($paramName in $__boundParameters.Keys|
            Where-Object {!$__PARAMETERMAP[$_].ApplyToExecutable}|
            Sort-Object {$__PARAMETERMAP[$_].OriginalPosition}) {
        $value = $__boundParameters[$paramName]
        $param = $__PARAMETERMAP[$paramName]
        if ($param) {
            if ($value -is [switch]) {
                 if ($value.IsPresent) {
                     if ($param.OriginalName) { $__commandArgs += $param.OriginalName }
                 }
                 elseif ($param.DefaultMissingValue) { $__commandArgs += $param.DefaultMissingValue }
            }
            elseif ( $param.NoGap ) {
                $pFmt = "{0}{1}"
                if($value -match "\s") { $pFmt = "{0}""{1}""" }
                $__commandArgs += $pFmt -f $param.OriginalName, $value
            }
            else {
                if($param.OriginalName) { $__commandArgs += $param.OriginalName }
                $__commandArgs += $value | Foreach-Object {$_}
            }
        }
    }
    $__commandArgs = $__commandArgs | Where-Object {$_ -ne $null}
    if ($__boundParameters["Debug"]){wait-debugger}
    if ( $__boundParameters["Verbose"]) {
         Write-Verbose -Verbose -Message foundry
         $__commandArgs | Write-Verbose -Verbose
    }
    $__handlerInfo = $__outputHandlers[$PSCmdlet.ParameterSetName]
    if (! $__handlerInfo ) {
        $__handlerInfo = $__outputHandlers["Default"] # Guaranteed to be present
    }
    $__handler = $__handlerInfo.Handler
    if ( $PSCmdlet.ShouldProcess("foundry $__commandArgs")) {
    # check for the application and throw if it cannot be found
        if ( -not (Get-Command -ErrorAction Ignore "foundry")) {
          throw "Cannot find executable 'foundry'"
        }
        if ( $__handlerInfo.StreamOutput ) {
            & "foundry" $__commandArgs | & $__handler
        }
        else {
            $result = & "foundry" $__commandArgs
            & $__handler $result
        }
    }
  } # end PROCESS

<#
.SYNOPSIS
Remove a cached Foundry Local model.

.DESCRIPTION
Removes a model from the local cache.

.PARAMETER Model
Model ID or alias to delete. Use '*' to delete all cached models.


.PARAMETER Device
Select a model that is valid for the specified device. Valid values: Auto, CPU, GPU, NPU.


.PARAMETER All
Remove all models matching the specified alias instead of just the best match.


.PARAMETER Yes
Remove the model from cache without confirmation prompt.



.EXAMPLE
PS> Remove-FoundryLocalCachedModel -Model 'phi-4-mini'

Removes the phi-4-mini model from the cache.
Original Command: foundry cache remove phi-4-mini


.EXAMPLE
PS> Remove-FoundryLocalCachedModel -Model '*' -Confirm:$false

Removes all cached models without confirmation.
Original Command: foundry cache remove * --yes


#>
}

# Dot-source public functions
$publicPath = Join-Path -Path $PSScriptRoot -ChildPath 'public'
if (Test-Path -Path $publicPath) {
    Get-ChildItem -Path $publicPath -Filter '*.ps1' -File | ForEach-Object {
        . $_.FullName
    }
}
