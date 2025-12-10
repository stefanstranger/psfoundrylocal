function Start-FoundryLocalChatSession {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Model,

        [Parameter()]
        [ValidateSet('Auto', 'CPU', 'GPU', 'NPU')]
        [string]$Device = 'Auto',

        [Parameter()]
        [int]$TimeToLive,

        [Parameter()]
        [switch]$Retain,

        [Parameter()]
        [string]$Token,

        [Parameter()]
        [ValidateSet('trace', 'debug', 'info', 'warn', 'error', 'fatal')]
        [string]$LogLevel
    )

    <#
    .SYNOPSIS
        Starts an interactive Foundry Local chat session.

    .DESCRIPTION
        Launches `foundry model run` in interactive mode so you can
        have a multi-turn conversation with the selected model. The
        process remains attached to the current console, and input
        and output are not parsed or captured by PowerShell.

    .PARAMETER Model
        Name or alias of the model to run.

    .PARAMETER Device
        Device to target for the model. Default is Auto.

    .PARAMETER TimeToLive
        Optional time-to-live (in seconds) for the model.

    .PARAMETER Retain
        Keep the model loaded after the chat session ends.

    .PARAMETER Token
        Access token for authentication.

    .PARAMETER LogLevel
        Log level for the underlying Foundry Local process.

    .EXAMPLE
        PS> Start-FoundryLocalChatSession -Model 'phi-4-mini'

        Starts an interactive chat session with the phi-4-mini model.

    .EXAMPLE
        PS> Start-FoundryLocalChatSession -Model 'phi-4-mini' -Device GPU

        Starts an interactive chat session using the GPU variant of the model.
    #>

    if (-not (Get-Command -ErrorAction Ignore 'foundry')) {
        throw "Cannot find executable 'foundry'"
    }

    $args = @('model', 'run', $Model)

    if ($Device -and $Device -ne 'Auto') {
        $args += @('--device', $Device)
    }

    if ($PSBoundParameters.ContainsKey('TimeToLive')) {
        $args += @('--ttl', $TimeToLive)
    }

    if ($Retain.IsPresent) {
        $args += '--retain'
    }

    if ($Token) {
        $args += @('--token', $Token)
    }

    if ($LogLevel) {
        $args += @('--log-level', $LogLevel)
    }

    if ($PSBoundParameters.ContainsKey('Verbose') -and $VerbosePreference -ne 'SilentlyContinue') {
        Write-Verbose -Message ('foundry {0}' -f ($args -join ' '))
    }

    & 'foundry' @args
}
