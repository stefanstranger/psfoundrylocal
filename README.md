# psfoundrylocal

A PowerShell module for [Foundry Local](https://learn.microsoft.com/en-us/azure/ai-foundry/foundry-local/) CLI - an on-device AI inference solution.

This module wraps the Foundry Local command-line interface using [Microsoft.PowerShell.Crescendo](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.crescendo/), providing PowerShell cmdlets for managing AI models, the inference service, and local model cache.

## Features

- **Object-oriented output**: All cmdlets return PowerShell objects that can be piped and manipulated
- **Integrated help**: Get-Help works for all cmdlets with examples
- **Pipeline support**: Chain commands together for powerful workflows
- **Tab completion**: Parameter names and values support tab completion
- **Consistent naming**: Follows PowerShell verb-noun conventions
- **WhatIf/Confirm support**: State-changing cmdlets support `-WhatIf` and `-Confirm` parameters
- **PSScriptAnalyzer compliant**: Follows PowerShell best practices

## Prerequisites

- **Foundry Local CLI**: Must be installed and available on PATH. See [Foundry Local installation guide](https://learn.microsoft.com/en-us/azure/ai-foundry/foundry-local/get-started)
- **PowerShell 5.1+**: Works on both Windows PowerShell 5.1 and PowerShell 7+

## Installation

### From PowerShell Gallery (coming soon)

```powershell
Install-Module -Name psfoundrylocal -Scope CurrentUser
```

### Manual Installation

1. Clone or download this repository
2. Copy the `src` folder contents to one of your PowerShell module paths:
   ```powershell
   # User-specific
   $env:USERPROFILE\Documents\PowerShell\Modules\psfoundrylocal\
   
   # Or system-wide (requires admin)
   $env:ProgramFiles\PowerShell\Modules\psfoundrylocal\
   ```
3. Import the module:
   ```powershell
   Import-Module psfoundrylocal
   ```

## Quick Start

```powershell
# Import the module
Import-Module psfoundrylocal

# Check service status
Get-FoundryLocalService

# List available models
Get-FoundryLocalModel

# List only GPU models
Get-FoundryLocalModel -Filter 'device=GPU'

# Get detailed info about a model
Get-FoundryLocalModelInfo -Model 'phi-4-mini'

# Start the service
Start-FoundryLocalService

# Load a model
Start-FoundryLocalModel -Model 'phi-4-mini'

# Check loaded models
Get-FoundryLocalServiceModel

# Unload a model
Stop-FoundryLocalModel -Model 'phi-4-mini'

# View cached models
Get-FoundryLocalCache

# Get cache location
Get-FoundryLocalCacheLocation
```

## Available Cmdlets

### Model Management

| Cmdlet | Description |
|--------|-------------|
| `Get-FoundryLocalModel` | Lists all available models |
| `Get-FoundryLocalModelInfo` | Gets detailed information about a specific model |
| `Save-FoundryLocalModel` | Downloads a model to local cache |
| `Start-FoundryLocalModel` | Loads a model into the service |
| `Stop-FoundryLocalModel` | Unloads a model from the service |

### Service Management

| Cmdlet | Description |
|--------|-------------|
| `Get-FoundryLocalService` | Gets the current service status |
| `Get-FoundryLocalServiceModel` | Lists models loaded in the service |
| `Start-FoundryLocalService` | Starts the Foundry Local service |
| `Stop-FoundryLocalService` | Stops the Foundry Local service |
| `Restart-FoundryLocalService` | Restarts the Foundry Local service |

### Cache Management

| Cmdlet | Description |
|--------|-------------|
| `Get-FoundryLocalCache` | Lists all cached models |
| `Get-FoundryLocalCacheLocation` | Gets the cache directory path |
| `Set-FoundryLocalCacheLocation` | Changes the cache directory |
| `Remove-FoundryLocalCachedModel` | Removes a model from the cache |

## Examples

### Filtering Models

```powershell
# List GPU models
Get-FoundryLocalModel -Filter 'device=GPU'

# List CPU models
Get-FoundryLocalModel -Filter 'device=CPU'

# List chat completion models
Get-FoundryLocalModel -Filter 'task=chat-completion'

# List models by alias pattern (wildcard)
Get-FoundryLocalModel -Filter 'alias=phi*'

# Exclude GPU models
Get-FoundryLocalModel -Filter 'device=!GPU'
```

### Pipeline Operations

```powershell
# Get models and export to CSV
Get-FoundryLocalModel | Export-Csv -Path 'models.csv' -NoTypeInformation

# Find large models (> 5GB) for GPU
Get-FoundryLocalModel -Filter 'device=GPU' | 
    Where-Object { [double]($_.FileSize -replace '[^\d.]', '') -gt 5 }

# Get MIT-licensed models
Get-FoundryLocalModel | Where-Object { $_.License -eq 'MIT' }
```

### Service Workflow

```powershell
# Full workflow: start service, load model, check status
Start-FoundryLocalService
Start-FoundryLocalModel -Model 'phi-4-mini' -TimeToLive 600
Get-FoundryLocalServiceModel

# Cleanup
Stop-FoundryLocalModel -Model 'phi-4-mini'
```

### Cache Management

```powershell
# View cache info
$cache = Get-FoundryLocalCacheLocation
Write-Host "Cache path: $($cache.Path)"
Write-Host "Cache exists: $($cache.Exists)"

# Download a model without running it
Save-FoundryLocalModel -Model 'phi-4-mini' -Device GPU

# Remove a cached model
Remove-FoundryLocalCachedModel -Model 'phi-4-mini' -Confirm:$false
```

### Using WhatIf and Confirm

State-changing cmdlets support `-WhatIf` to preview actions without executing them:

```powershell
# Preview what would happen without actually stopping the service
Stop-FoundryLocalService -WhatIf
# Output: What if: Performing the operation "Stop-FoundryLocalService" on target "foundry service stop".

# Preview model removal
Remove-FoundryLocalCachedModel -Model 'phi-4-mini' -WhatIf

# Require confirmation before starting service
Start-FoundryLocalService -Confirm
```

The following cmdlets support `-WhatIf` and `-Confirm`:

- `Save-FoundryLocalModel`
- `Start-FoundryLocalModel`
- `Stop-FoundryLocalModel`
- `Start-FoundryLocalService`
- `Stop-FoundryLocalService`
- `Restart-FoundryLocalService`
- `Set-FoundryLocalCacheLocation`
- `Remove-FoundryLocalCachedModel`

## Output Types

The module returns strongly-typed objects for better pipeline integration:

- `psfoundrylocal.Model` - Model information from `Get-FoundryLocalModel`
- `psfoundrylocal.ModelInfo` - Detailed model info from `Get-FoundryLocalModelInfo`
- `psfoundrylocal.ServiceStatus` - Service status from `Get-FoundryLocalService`
- `psfoundrylocal.CachedModel` - Cached model info from `Get-FoundryLocalCache`
- `psfoundrylocal.CacheLocation` - Cache path info from `Get-FoundryLocalCacheLocation`

## Development

### Building from Source

This module is built using Microsoft.PowerShell.Crescendo. To regenerate the module:

```powershell
# Install Crescendo
Install-Module Microsoft.PowerShell.Crescendo -Scope CurrentUser

# Load output handlers
. .\src\outputhandlers.ps1

# Generate module
Export-CrescendoModule -ConfigurationFile .\src\psfoundrylocal.crescendo.json `
                       -ModuleName .\src\psfoundrylocal.psm1 -Force
```

### Running Tests

```powershell
# Install Pester if needed
Install-Module Pester -Scope CurrentUser -Force

# Run all tests
Invoke-Pester -Path .\tests\

# Run only unit tests
Invoke-Pester -Path .\tests\OutputHandlers.Tests.ps1

# Run integration tests (requires Foundry Local CLI)
Invoke-Pester -Path .\tests\Integration.Tests.ps1
```

## Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Add tests for new functionality
4. Submit a pull request

## License

MIT License - see [LICENSE](LICENSE) for details.

## Related Links

- [Foundry Local Documentation](https://learn.microsoft.com/en-us/azure/ai-foundry/foundry-local/)
- [Foundry Local CLI Reference](https://learn.microsoft.com/en-us/azure/ai-foundry/foundry-local/reference/reference-cli)
- [Microsoft.PowerShell.Crescendo](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.crescendo/)
- [Crescendo GitHub Repository](https://github.com/PowerShell/Crescendo)

## Acknowledgments

- Built with [Microsoft.PowerShell.Crescendo](https://github.com/PowerShell/Crescendo)
- Inspired by the [Crescendo blog series](https://devblogs.microsoft.com/powershell-community/my-crescendo-journey/) by Sean Wheeler
