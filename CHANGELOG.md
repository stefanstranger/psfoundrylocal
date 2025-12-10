# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [0.0.1] - 2025-12-10

### Added
- Initial `psfoundrylocal` module generated with Microsoft.PowerShell.Crescendo.
- Cmdlets for model management:
  - `Get-FoundryLocalModel`
  - `Get-FoundryLocalModelInfo`
  - `Save-FoundryLocalModel`
  - `Start-FoundryLocalModel`
  - `Stop-FoundryLocalModel`
- Cmdlets for service management:
  - `Get-FoundryLocalService`
  - `Get-FoundryLocalServiceModel`
  - `Start-FoundryLocalService`
  - `Stop-FoundryLocalService`
  - `Restart-FoundryLocalService`
- Cmdlets for cache management:
  - `Get-FoundryLocalCache`
  - `Get-FoundryLocalCacheLocation`
  - `Set-FoundryLocalCacheLocation`
  - `Remove-FoundryLocalCachedModel`
- Output handler functions to parse Foundry Local CLI output into typed PowerShell objects.
- Pester tests for output handlers and basic integration scenarios.
- Sample script `samples/demo.ps1` demonstrating common workflows.

### Changed
- Enabled `SupportsShouldProcess` on all state-changing cmdlets (`Save-`, `Start-`, `Stop-`, `Restart-`, `Set-`, `Remove-`) and verified `-WhatIf`/`-Confirm` behavior.
- Updated `samples/demo.ps1` to follow PowerShell best practices (splatting, format operator, `[CmdletBinding()]`, explicit parameter names).
- Revised README to document features, usage examples, and `-WhatIf`/`-Confirm` support.

### Fixed
- `Get-FoundryLocalCache` output handler to correctly parse the current `foundry cache list` table format (including wrapped lines and emoji/garbled characters), returning `psfoundrylocal.CachedModel` objects with `Alias` and `ModelId`.
- Encoding issues by saving module files with UTF-8 BOM to handle non-ASCII CLI output.
- Minor formatting and trailing whitespace issues flagged by `Invoke-ScriptAnalyzer`.
