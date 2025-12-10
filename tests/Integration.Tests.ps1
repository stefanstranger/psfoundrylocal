#Requires -Modules Pester

<#
.SYNOPSIS
    Integration tests for psfoundrylocal module.
.DESCRIPTION
    These tests validate the complete cmdlet functionality by
    running against the actual Foundry Local CLI. These tests
    require Foundry Local to be installed and available on PATH.
#>

BeforeAll {
    # Import the module
    $modulePath = Join-Path $PSScriptRoot '..\src\psfoundrylocal.psd1'
    Import-Module $modulePath -Force

    # Check if foundry CLI is available
    $script:foundryAvailable = $null -ne (Get-Command 'foundry' -ErrorAction SilentlyContinue)
}

Describe 'Module Import' {
    It 'Should import the module successfully' {
        Get-Module psfoundrylocal | Should -Not -BeNullOrEmpty
    }

    It 'Should export Get-FoundryLocalModel' {
        Get-Command Get-FoundryLocalModel -Module psfoundrylocal | Should -Not -BeNullOrEmpty
    }

    It 'Should export Get-FoundryLocalModelInfo' {
        Get-Command Get-FoundryLocalModelInfo -Module psfoundrylocal | Should -Not -BeNullOrEmpty
    }

    It 'Should export Save-FoundryLocalModel' {
        Get-Command Save-FoundryLocalModel -Module psfoundrylocal | Should -Not -BeNullOrEmpty
    }

    It 'Should export Start-FoundryLocalModel' {
        Get-Command Start-FoundryLocalModel -Module psfoundrylocal | Should -Not -BeNullOrEmpty
    }

    It 'Should export Stop-FoundryLocalModel' {
        Get-Command Stop-FoundryLocalModel -Module psfoundrylocal | Should -Not -BeNullOrEmpty
    }

    It 'Should export Get-FoundryLocalService' {
        Get-Command Get-FoundryLocalService -Module psfoundrylocal | Should -Not -BeNullOrEmpty
    }

    It 'Should export Get-FoundryLocalServiceModel' {
        Get-Command Get-FoundryLocalServiceModel -Module psfoundrylocal | Should -Not -BeNullOrEmpty
    }

    It 'Should export Start-FoundryLocalService' {
        Get-Command Start-FoundryLocalService -Module psfoundrylocal | Should -Not -BeNullOrEmpty
    }

    It 'Should export Stop-FoundryLocalService' {
        Get-Command Stop-FoundryLocalService -Module psfoundrylocal | Should -Not -BeNullOrEmpty
    }

    It 'Should export Restart-FoundryLocalService' {
        Get-Command Restart-FoundryLocalService -Module psfoundrylocal | Should -Not -BeNullOrEmpty
    }

    It 'Should export Get-FoundryLocalCache' {
        Get-Command Get-FoundryLocalCache -Module psfoundrylocal | Should -Not -BeNullOrEmpty
    }

    It 'Should export Get-FoundryLocalCacheLocation' {
        Get-Command Get-FoundryLocalCacheLocation -Module psfoundrylocal | Should -Not -BeNullOrEmpty
    }

    It 'Should export Set-FoundryLocalCacheLocation' {
        Get-Command Set-FoundryLocalCacheLocation -Module psfoundrylocal | Should -Not -BeNullOrEmpty
    }

    It 'Should export Remove-FoundryLocalCachedModel' {
        Get-Command Remove-FoundryLocalCachedModel -Module psfoundrylocal | Should -Not -BeNullOrEmpty
    }
}

Describe 'Cmdlet Help' {
    Context 'Get-FoundryLocalModel Help' {
        It 'Should have synopsis' {
            $help = Get-Help Get-FoundryLocalModel
            $help.Synopsis | Should -Not -BeNullOrEmpty
        }

        It 'Should have description' {
            $help = Get-Help Get-FoundryLocalModel
            $help.Description | Should -Not -BeNullOrEmpty
        }

        It 'Should have examples' {
            $help = Get-Help Get-FoundryLocalModel -Examples
            $help.examples.example | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-FoundryLocalService Help' {
        It 'Should have synopsis' {
            $help = Get-Help Get-FoundryLocalService
            $help.Synopsis | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-FoundryLocalCache Help' {
        It 'Should have synopsis' {
            $help = Get-Help Get-FoundryLocalCache
            $help.Synopsis | Should -Not -BeNullOrEmpty
        }
    }
}

Describe 'Get-FoundryLocalModel' -Skip:(-not $script:foundryAvailable) {
    It 'Should return model objects' {
        $models = Get-FoundryLocalModel
        $models | Should -Not -BeNullOrEmpty
    }

    It 'Should return objects with Alias property' {
        $models = Get-FoundryLocalModel
        $models[0].Alias | Should -Not -BeNullOrEmpty
    }

    It 'Should return objects with Device property' {
        $models = Get-FoundryLocalModel
        $models[0].Device | Should -BeIn @('CPU', 'GPU', 'NPU')
    }

    It 'Should support Filter parameter' {
        $gpuModels = Get-FoundryLocalModel -Filter 'device=GPU'
        # This should not throw an error
        $gpuModels | Should -Not -BeNullOrEmpty
    }
}

Describe 'Get-FoundryLocalService' -Skip:(-not $script:foundryAvailable) {
    It 'Should return service status' {
        $status = Get-FoundryLocalService
        $status | Should -Not -BeNullOrEmpty
    }

    It 'Should have IsRunning property' {
        $status = Get-FoundryLocalService
        $status.IsRunning | Should -BeOfType [bool]
    }

    It 'Should have Message property' {
        $status = Get-FoundryLocalService
        $status.Message | Should -Not -BeNullOrEmpty
    }
}

Describe 'Get-FoundryLocalCache' -Skip:(-not $script:foundryAvailable) {
    It 'Should return cached models or empty result' {
        # This should not throw an error
        $cache = Get-FoundryLocalCache
        # May be empty if nothing is cached
        $cache | Should -Not -Be $null
    }
}

Describe 'Get-FoundryLocalCacheLocation' -Skip:(-not $script:foundryAvailable) {
    It 'Should return cache location' {
        $location = Get-FoundryLocalCacheLocation
        $location | Should -Not -BeNullOrEmpty
    }

    It 'Should have Path property' {
        $location = Get-FoundryLocalCacheLocation
        $location.Path | Should -Not -BeNullOrEmpty
    }

    It 'Should have Exists property' {
        $location = Get-FoundryLocalCacheLocation
        $location.Exists | Should -BeOfType [bool]
    }
}

Describe 'Get-FoundryLocalServiceModel' -Skip:(-not $script:foundryAvailable) {
    It 'Should return loaded models status' {
        $loaded = Get-FoundryLocalServiceModel
        $loaded | Should -Not -BeNullOrEmpty
    }

    It 'Should have ModelsLoaded property' {
        $loaded = Get-FoundryLocalServiceModel
        $loaded.ModelsLoaded | Should -BeOfType [int]
    }
}

Describe 'Parameter Validation' {
    Context 'Get-FoundryLocalModelInfo' {
        It 'Should require Model parameter' {
            { Get-FoundryLocalModelInfo } | Should -Throw
        }

        It 'Should accept Model parameter' {
            $cmd = Get-Command Get-FoundryLocalModelInfo
            $cmd.Parameters.Model | Should -Not -BeNullOrEmpty
        }

        It 'Should have Device parameter with ValidateSet' {
            $cmd = Get-Command Get-FoundryLocalModelInfo
            $cmd.Parameters.Device.Attributes | 
                Where-Object { $_ -is [System.Management.Automation.ValidateSetAttribute] } |
                Should -Not -BeNullOrEmpty
        }
    }

    Context 'Save-FoundryLocalModel' {
        It 'Should require Model parameter' {
            { Save-FoundryLocalModel } | Should -Throw
        }

        It 'Should have Force switch parameter' {
            $cmd = Get-Command Save-FoundryLocalModel
            $cmd.Parameters.Force.SwitchParameter | Should -BeTrue
        }
    }

    Context 'Start-FoundryLocalModel' {
        It 'Should require Model parameter' {
            { Start-FoundryLocalModel } | Should -Throw
        }

        It 'Should have TimeToLive parameter' {
            $cmd = Get-Command Start-FoundryLocalModel
            $cmd.Parameters.TimeToLive | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Stop-FoundryLocalModel' {
        It 'Should require Model parameter' {
            { Stop-FoundryLocalModel } | Should -Throw
        }

        It 'Should have All switch parameter' {
            $cmd = Get-Command Stop-FoundryLocalModel
            $cmd.Parameters.All.SwitchParameter | Should -BeTrue
        }
    }

    Context 'Set-FoundryLocalCacheLocation' {
        It 'Should require Path parameter' {
            { Set-FoundryLocalCacheLocation } | Should -Throw
        }
    }

    Context 'Remove-FoundryLocalCachedModel' {
        It 'Should require Model parameter' {
            { Remove-FoundryLocalCachedModel } | Should -Throw
        }

        It 'Should support ShouldProcess' {
            $cmd = Get-Command Remove-FoundryLocalCachedModel
            $cmd.CmdletBinding | Should -BeTrue
        }
    }
}
