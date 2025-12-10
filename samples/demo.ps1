<#
.SYNOPSIS
    Example script demonstrating psfoundrylocal module usage.
.DESCRIPTION
    This script shows common workflows for using the psfoundrylocal
    PowerShell module to interact with Foundry Local CLI.
.NOTES
    Author: Stefan Stranger
    Date: December 2025
.EXAMPLE
    .\demo.ps1
    Runs the full demonstration of psfoundrylocal module capabilities.
#>

# Import the module
Import-Module psfoundrylocal -Force

#region Service Management
# Check service status
Write-Host '=== Service Status ===' -ForegroundColor Cyan
$status = Get-FoundryLocalService
if ($status.IsRunning) {
    Write-Verbose -Message ('Service is running at {0}' -f $status.Endpoint)
    Write-Host ('Service is running at {0}' -f $status.Endpoint) -ForegroundColor Green
    Write-Host ('Process ID: {0}' -f $status.ProcessId)
}
else {
    Write-Host 'Service is not running. Starting...' -ForegroundColor Yellow
    $startResult = Start-FoundryLocalService
    if ($startResult.Success) {
        Write-Host ('Service started at {0}' -f $startResult.Endpoint) -ForegroundColor Green
    }
}
#endregion

#region Model Discovery
# List all available models
Write-Host "`n=== Available Models ===" -ForegroundColor Cyan
$models = Get-FoundryLocalModel
$models | Format-Table Alias, Device, Task, FileSize, License -AutoSize

# List GPU models only
Write-Host "`n=== GPU Models ===" -ForegroundColor Cyan
$gpuModels = Get-FoundryLocalModel -Filter 'device=GPU'
$gpuModels | Format-Table Alias, Device, FileSize -AutoSize

# List chat completion models
Write-Host "`n=== Chat Completion Models ===" -ForegroundColor Cyan
$chatModels = Get-FoundryLocalModel -Filter 'task=chat-completion'
$chatModels | Format-Table Alias, Device, Task -AutoSize

# Get detailed info about a specific model
Write-Host "`n=== Model Info: phi-4-mini ===" -ForegroundColor Cyan
$modelInfo = Get-FoundryLocalModelInfo -Model 'phi-4-mini'
$modelInfo | Format-List
#endregion

#region Cache Management
# Check cache location
Write-Host "`n=== Cache Location ===" -ForegroundColor Cyan
$cacheLocation = Get-FoundryLocalCacheLocation
Write-Host ('Cache path: {0}' -f $cacheLocation.Path)
Write-Host ('Exists: {0}' -f $cacheLocation.Exists)

# List cached models
Write-Host "`n=== Cached Models ===" -ForegroundColor Cyan
$cachedModels = Get-FoundryLocalCache
if ($cachedModels) {
    $cachedModels | Format-Table Alias, ModelId -AutoSize
}
else {
    Write-Host 'No models cached locally.' -ForegroundColor Yellow
}
#endregion

#region Model Loading
# Load a model into the service
Write-Host "`n=== Loading Model ===" -ForegroundColor Cyan
$loadParams = @{
    Model      = 'phi-4-mini'
    TimeToLive = 300
}
$loadResult = Start-FoundryLocalModel @loadParams
if ($loadResult.Success) {
    Write-Host 'Model loaded successfully' -ForegroundColor Green
}
else {
    Write-Host ('Load result: {0}' -f $loadResult.Message) -ForegroundColor Yellow
}

# Check loaded models
Write-Host "`n=== Loaded Models ===" -ForegroundColor Cyan
$loadedModels = Get-FoundryLocalServiceModel
Write-Host ('Models loaded: {0}' -f $loadedModels.ModelsLoaded)
if ($loadedModels.Models) {
    $loadedModels.Models | ForEach-Object { Write-Host ('  - {0}' -f $_) }
}

# Unload the model
Write-Host "`n=== Unloading Model ===" -ForegroundColor Cyan
$unloadResult = Stop-FoundryLocalModel -Model 'phi-4-mini'
Write-Host ('Unload result: {0}' -f $unloadResult.Message)
#endregion

#region Pipeline Examples
# Pipeline: Get GPU models larger than 2GB
Write-Host "`n=== GPU Models > 2GB ===" -ForegroundColor Cyan
Get-FoundryLocalModel -Filter 'device=GPU' |
    Where-Object {
        $size = $_.FileSize -replace '[^\d.]', ''
        [double]$size -gt 2
    } |
    Sort-Object { [double]($_.FileSize -replace '[^\d.]', '') } |
    Format-Table Alias, FileSize, License

# Pipeline: Export model list to CSV
Write-Host "`n=== Exporting Models to CSV ===" -ForegroundColor Cyan
$exportPath = Join-Path -Path $env:TEMP -ChildPath 'foundry-models.csv'
$exportParams = @{
    Path              = $exportPath
    NoTypeInformation = $true
}
Get-FoundryLocalModel | Export-Csv @exportParams
Write-Host ('Models exported to: {0}' -f $exportPath)
#endregion

Write-Host "`n=== Demo Complete ===" -ForegroundColor Green
