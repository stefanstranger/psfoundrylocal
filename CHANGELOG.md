# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [0.1.2] - 2025-12-12

### Added
- `Test-FoundryLocalUpdate` function exported in module manifest.
- Pipeline examples in README documentation.
- Utility section in README for `Test-FoundryLocalUpdate` cmdlet.
- `psfoundrylocal.UpdateInfo` output type documented in README.

### Fixed
- `Test-FoundryLocalUpdate` was not visible because it was missing from `FunctionsToExport` in the module manifest.

## [0.1.1] - 2025-12-12

### Added
- `Test-FoundryLocalUpdate` function to check for Foundry Local CLI updates by comparing installed version with latest GitHub release tag.
- Pipeline support for cmdlets - parameters now accept input via `ValueFromPipelineByPropertyName` using the `Alias` property.
- GitHub Copilot instructions file (`.github/workflows/instructions/psfoundrylocal.instructions.md`) with coding standards and Crescendo guidance.

### Changed
- Updated Pester tests to check parameter metadata instead of invoking cmdlets with missing mandatory parameters (prevents interactive prompts during test runs).
- Code style improvements to `Test-FoundryLocalUpdate` following instruction file guidelines (splatting, format operator, explicit parameter names).

### Fixed
- Parameter validation tests no longer prompt for input when testing mandatory parameters.

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

### Added

- `Start-FoundryLocalChatSession` helper for launching interactive `foundry model run` chat sessions from PowerShell without parsing output.
- GitHub Actions workflow (`.github/workflows/release.yml`) for automated validation, release creation, and PowerShell Gallery publishing.
- Module `Description` field in manifest (required for PSGallery).

### Changed
- Enabled `SupportsShouldProcess` on all state-changing cmdlets (`Save-`, `Start-`, `Stop-`, `Restart-`, `Set-`, `Remove-`) and verified `-WhatIf`/`-Confirm` behavior.
- Updated `samples/demo.ps1` to follow PowerShell best practices (splatting, format operator, `[CmdletBinding()]`, explicit parameter names).
- Revised README to document features, usage examples, and `-WhatIf`/`-Confirm` support.

- Removed the experimental `Invoke-FoundryLocalRun` Crescendo cmdlet in favor of the interactive `Start-FoundryLocalChatSession` function to better align with multi-turn chat behavior.

### Fixed

- `Get-FoundryLocalCache` output handler to correctly parse the current `foundry cache list` table format (including wrapped lines and emoji/garbled characters), returning `psfoundrylocal.CachedModel` objects with `Alias` and `ModelId`.
- Encoding issues by saving module files with UTF-8 BOM to handle non-ASCII CLI output.
- Minor formatting and trailing whitespace issues flagged by `Invoke-ScriptAnalyzer`.
- `Convert-FoundryLocalServiceStatusOutput` now correctly detects "not running" status (fixed regex ordering to avoid false positives).
- Pester tests now dot-source `outputhandlers.ps1` directly for cross-platform compatibility in CI.
