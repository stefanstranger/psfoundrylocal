function Test-FoundryLocalUpdate {
    <#
    .SYNOPSIS
    Checks if a newer version of Foundry Local is available.

    .DESCRIPTION
    Compares the locally installed Foundry Local version with the latest release
    version available on GitHub. Returns an object with version information and
    whether an update is available.

    .EXAMPLE
    PS> Test-FoundryLocalUpdate

    InstalledVersion : 0.8.113
    LatestVersion    : 0.8.113
    UpdateAvailable  : False
    ReleaseUrl       : https://github.com/microsoft/Foundry-Local/releases/tag/v0.8.113

    Checks if an update is available for Foundry Local.

    .EXAMPLE
    PS> Test-FoundryLocalUpdate | Where-Object UpdateAvailable

    Returns the update information only if an update is available.

    .EXAMPLE
    PS> if ((Test-FoundryLocalUpdate).UpdateAvailable) { Write-Host "Update available!" }

    Checks if an update is available and displays a message.

    .OUTPUTS
    psfoundrylocal.UpdateInfo
    Returns a custom object with InstalledVersion, LatestVersion, UpdateAvailable, and ReleaseUrl properties.

    .NOTES
    Requires internet access to check the latest release on GitHub.
    Uses the GitHub API to retrieve release information.

    .LINK
    https://github.com/microsoft/Foundry-Local/releases
    #>
    [CmdletBinding()]
    [OutputType('psfoundrylocal.UpdateInfo')]
    param()

    begin {
        # GitHub API URL for tags (releases/latest doesn't work if there are only tags, not releases)
        $gitHubApiUrl = 'https://api.github.com/repos/microsoft/Foundry-Local/tags'
        $releasePageUrl = 'https://github.com/microsoft/Foundry-Local/releases'
    }

    process {
        # Get installed version
        Write-Verbose "Getting installed Foundry Local version..."
        
        if (-not (Get-Command -Name 'foundry' -ErrorAction SilentlyContinue)) {
            throw "Foundry Local is not installed or 'foundry' command is not in PATH."
        }

        try {
            $installedVersionOutput = & foundry --version 2>&1
            # Version format: 0.8.113+70167233c5 - extract just the version number before the +
            $installedVersion = ($installedVersionOutput -split '\+')[0].Trim()
            Write-Verbose "Installed version: $installedVersion"
        }
        catch {
            throw "Failed to get installed Foundry Local version: $_"
        }

        # Get latest release from GitHub
        Write-Verbose "Checking latest release on GitHub..."
        
        try {
            $headers = @{
                'Accept' = 'application/vnd.github.v3+json'
                'User-Agent' = 'psfoundrylocal-powershell-module'
            }
            
            $response = Invoke-RestMethod -Uri $gitHubApiUrl -Headers $headers -Method Get -ErrorAction Stop
            
            # Tags API returns an array, get the first (most recent) tag
            # Tag format: v0.8.113 - remove the 'v' prefix
            $latestTag = $response | Select-Object -First 1
            $latestVersion = $latestTag.name -replace '^v', ''
            $releaseUrl = "https://github.com/microsoft/Foundry-Local/releases/tag/$($latestTag.name)"
            
            Write-Verbose "Latest version: $latestVersion"
        }
        catch {
            throw "Failed to check latest release on GitHub: $_"
        }

        # Compare versions
        Write-Verbose "Comparing versions..."
        
        try {
            $installedVersionObj = [System.Version]::Parse($installedVersion)
            $latestVersionObj = [System.Version]::Parse($latestVersion)
            $updateAvailable = $latestVersionObj -gt $installedVersionObj
        }
        catch {
            # If version parsing fails, fall back to string comparison
            Write-Verbose "Version parsing failed, using string comparison: $_"
            $updateAvailable = $latestVersion -ne $installedVersion
        }

        # Return result
        [PSCustomObject]@{
            PSTypeName       = 'psfoundrylocal.UpdateInfo'
            InstalledVersion = $installedVersion
            LatestVersion    = $latestVersion
            UpdateAvailable  = $updateAvailable
            ReleaseUrl       = $releaseUrl
        }
    }
}
