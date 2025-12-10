#Requires -Modules Pester

<#
.SYNOPSIS
    Unit tests for psfoundrylocal module output handlers.
.DESCRIPTION
    These tests validate the output handler functions that parse
    the Foundry Local CLI output and convert it to PowerShell objects.
#>

BeforeAll {
    # Dot-source the output handlers directly for testing
    # These functions are embedded in the module but not exported,
    # so we test them by sourcing the original file
    $handlersPath = Join-Path $PSScriptRoot '../src/outputhandlers.ps1'
    if (-not (Test-Path $handlersPath)) {
        throw "Cannot find outputhandlers.ps1 at: $handlersPath"
    }
    . $handlersPath
}

Describe 'Convert-FoundryLocalModelListOutput' {
    Context 'When parsing valid model list output' {
        BeforeAll {
            $sampleOutput = @(
                '🟢 Service is Started on http://127.0.0.1:44549/, PID 19804!'
                'Alias                          Device     Task           File Size    License      Model ID'
                '-----------------------------------------------------------------------------------------------'
                'phi-4-mini                     GPU        chat, tools    2.15 GB      MIT          phi-4-mini-instruct-openvino-gpu:2'
                '                               CPU        chat, tools    4.80 GB      MIT          Phi-4-mini-instruct-generic-cpu:5'
            )
        }

        It 'Should return model objects' {
            $result = Convert-FoundryLocalModelListOutput -Output $sampleOutput
            $result | Should -Not -BeNullOrEmpty
        }

        It 'Should have correct PSTypeName' {
            $result = Convert-FoundryLocalModelListOutput -Output $sampleOutput
            $result[0].PSObject.TypeNames | Should -Contain 'psfoundrylocal.Model'
        }

        It 'Should parse Alias correctly' {
            $result = Convert-FoundryLocalModelListOutput -Output $sampleOutput
            $result[0].Alias | Should -Be 'phi-4-mini'
        }

        It 'Should parse Device correctly' {
            $result = Convert-FoundryLocalModelListOutput -Output $sampleOutput
            $result[0].Device | Should -Be 'GPU'
        }

        It 'Should parse Task correctly' {
            $result = Convert-FoundryLocalModelListOutput -Output $sampleOutput
            $result[0].Task | Should -Match 'chat'
        }

        It 'Should parse FileSize correctly' {
            $result = Convert-FoundryLocalModelListOutput -Output $sampleOutput
            $result[0].FileSize | Should -Match '\d+.*GB'
        }

        It 'Should parse License correctly' {
            $result = Convert-FoundryLocalModelListOutput -Output $sampleOutput
            $result[0].License | Should -Be 'MIT'
        }
    }

    Context 'When parsing empty output' {
        It 'Should return nothing for null input' {
            $result = Convert-FoundryLocalModelListOutput -Output $null
            $result | Should -BeNullOrEmpty
        }

        It 'Should return nothing for empty array' {
            $result = Convert-FoundryLocalModelListOutput -Output @()
            $result | Should -BeNullOrEmpty
        }
    }

    Context 'When parsing output with status messages only' {
        BeforeAll {
            $statusOnlyOutput = @(
                '🟢 Service is Started on http://127.0.0.1:44549/, PID 19804!'
                '🕗 Downloading complete!...'
                'Successfully downloaded and registered the following EPs: OpenVINOExecutionProvider.'
            )
        }

        It 'Should return nothing when no model data present' {
            $result = Convert-FoundryLocalModelListOutput -Output $statusOnlyOutput
            $result | Should -BeNullOrEmpty
        }
    }
}

Describe 'Convert-FoundryLocalServiceStatusOutput' {
    Context 'When service is running' {
        BeforeAll {
            $runningOutput = @('🟢 Service is Started on http://127.0.0.1:44549/, PID 19804!')
        }

        It 'Should return a ServiceStatus object' {
            $result = Convert-FoundryLocalServiceStatusOutput -Output $runningOutput
            $result | Should -Not -BeNullOrEmpty
        }

        It 'Should set IsRunning to true' {
            $result = Convert-FoundryLocalServiceStatusOutput -Output $runningOutput
            $result.IsRunning | Should -BeTrue
        }

        It 'Should parse Endpoint correctly' {
            $result = Convert-FoundryLocalServiceStatusOutput -Output $runningOutput
            $result.Endpoint | Should -Be 'http://127.0.0.1:44549/'
        }

        It 'Should parse Port correctly' {
            $result = Convert-FoundryLocalServiceStatusOutput -Output $runningOutput
            $result.Port | Should -Be 44549
        }

        It 'Should parse ProcessId correctly' {
            $result = Convert-FoundryLocalServiceStatusOutput -Output $runningOutput
            $result.ProcessId | Should -Be 19804
        }
    }

    Context 'When service is not running' {
        BeforeAll {
            $stoppedOutput = @('🔴 Model management service is not running!', 'To start the service, run the following command: foundry service start')
        }

        It 'Should set IsRunning to false' {
            $result = Convert-FoundryLocalServiceStatusOutput -Output $stoppedOutput
            $result.IsRunning | Should -BeFalse
        }

        It 'Should have null Endpoint' {
            $result = Convert-FoundryLocalServiceStatusOutput -Output $stoppedOutput
            $result.Endpoint | Should -BeNullOrEmpty
        }
    }

    Context 'When output is empty' {
        It 'Should return nothing for null input' {
            $result = Convert-FoundryLocalServiceStatusOutput -Output $null
            $result | Should -BeNullOrEmpty
        }
    }
}

Describe 'Convert-FoundryLocalCacheListOutput' {
    Context 'When parsing valid cache list output' {
        BeforeAll {
            $cacheOutput = @(
                'Models cached on device:'
                '   Alias                                             Model ID'
                '💾 mistral-7b-v0.2                                   Mistral-7B-Instruct-v0-2-openvino-gpu:1'
                '💾 phi-3-mini-4k                                     Phi-3-mini-4k-instruct-openvino-gpu:1'
                '💾 qwen2.5-1.5b                                      qwen2.5-1.5b-instruct-openvino-gpu:2'
            )
        }

        It 'Should return cached model objects' {
            $result = Convert-FoundryLocalCacheListOutput -Output $cacheOutput
            $result | Should -Not -BeNullOrEmpty
        }

        It 'Should have correct PSTypeName' {
            $result = Convert-FoundryLocalCacheListOutput -Output $cacheOutput
            $result[0].PSObject.TypeNames | Should -Contain 'psfoundrylocal.CachedModel'
        }

        It 'Should parse Alias correctly' {
            $result = Convert-FoundryLocalCacheListOutput -Output $cacheOutput
            $result[0].Alias | Should -Be 'mistral-7b-v0.2'
        }

        It 'Should parse ModelId correctly' {
            $result = Convert-FoundryLocalCacheListOutput -Output $cacheOutput
            $result[0].ModelId | Should -Be 'Mistral-7B-Instruct-v0-2-openvino-gpu:1'
        }

        It 'Should return multiple cached models' {
            $result = @(Convert-FoundryLocalCacheListOutput -Output $cacheOutput)
            $result.Count | Should -BeGreaterThan 1
        }
    }

    Context 'When cache is empty' {
        It 'Should return nothing for null input' {
            $result = Convert-FoundryLocalCacheListOutput -Output $null
            $result | Should -BeNullOrEmpty
        }
    }
}

Describe 'Convert-FoundryLocalCacheLocationOutput' {
    Context 'When parsing cache location output' {
        BeforeAll {
            $locationOutput = @('💾 Cache directory path: C:\Users\testuser\.foundry\cache\models')
        }

        It 'Should return a CacheLocation object' {
            $result = Convert-FoundryLocalCacheLocationOutput -Output $locationOutput
            $result | Should -Not -BeNullOrEmpty
        }

        It 'Should parse Path correctly' {
            $result = Convert-FoundryLocalCacheLocationOutput -Output $locationOutput
            $result.Path | Should -Be 'C:\Users\testuser\.foundry\cache\models'
        }

        It 'Should have correct PSTypeName' {
            $result = Convert-FoundryLocalCacheLocationOutput -Output $locationOutput
            $result.PSObject.TypeNames | Should -Contain 'psfoundrylocal.CacheLocation'
        }
    }

    Context 'When output is empty' {
        It 'Should return nothing for null input' {
            $result = Convert-FoundryLocalCacheLocationOutput -Output $null
            $result | Should -BeNullOrEmpty
        }
    }
}

Describe 'Convert-FoundryLocalServicePsOutput' {
    Context 'When no models are loaded' {
        BeforeAll {
            $noModelsOutput = @('No models are currently loaded in the service')
        }

        It 'Should return LoadedModels object' {
            $result = Convert-FoundryLocalServicePsOutput -Output $noModelsOutput
            $result | Should -Not -BeNullOrEmpty
        }

        It 'Should have ModelsLoaded = 0' {
            $result = Convert-FoundryLocalServicePsOutput -Output $noModelsOutput
            $result.ModelsLoaded | Should -Be 0
        }

        It 'Should have empty Models array' {
            $result = Convert-FoundryLocalServicePsOutput -Output $noModelsOutput
            $result.Models | Should -BeNullOrEmpty
        }
    }

    Context 'When output is empty' {
        It 'Should return nothing for null input' {
            $result = Convert-FoundryLocalServicePsOutput -Output $null
            $result | Should -BeNullOrEmpty
        }
    }
}

Describe 'Convert-FoundryLocalDownloadOutput' {
    Context 'When download succeeds' {
        BeforeAll {
            $successOutput = @('Model downloaded successfully')
        }

        It 'Should return DownloadResult object' {
            $result = Convert-FoundryLocalDownloadOutput -Output $successOutput
            $result | Should -Not -BeNullOrEmpty
        }

        It 'Should have Success = true' {
            $result = Convert-FoundryLocalDownloadOutput -Output $successOutput
            $result.Success | Should -BeTrue
        }
    }

    Context 'When download fails' {
        BeforeAll {
            $failOutput = @('Error: Model not found')
        }

        It 'Should have Success = false' {
            $result = Convert-FoundryLocalDownloadOutput -Output $failOutput
            $result.Success | Should -BeFalse
        }
    }

    Context 'When output is empty' {
        It 'Should return nothing for null input' {
            $result = Convert-FoundryLocalDownloadOutput -Output $null
            $result | Should -BeNullOrEmpty
        }
    }
}

Describe 'Convert-FoundryLocalLoadOutput' {
    Context 'When model loads successfully' {
        BeforeAll {
            $successOutput = @('Model loaded and ready')
        }

        It 'Should return LoadResult object' {
            $result = Convert-FoundryLocalLoadOutput -Output $successOutput
            $result | Should -Not -BeNullOrEmpty
        }

        It 'Should have Success = true' {
            $result = Convert-FoundryLocalLoadOutput -Output $successOutput
            $result.Success | Should -BeTrue
        }
    }

    Context 'When output is empty' {
        It 'Should return nothing for null input' {
            $result = Convert-FoundryLocalLoadOutput -Output $null
            $result | Should -BeNullOrEmpty
        }
    }
}

Describe 'Convert-FoundryLocalUnloadOutput' {
    Context 'When model unloads successfully' {
        BeforeAll {
            $successOutput = @('Model unloaded successfully')
        }

        It 'Should return UnloadResult object' {
            $result = Convert-FoundryLocalUnloadOutput -Output $successOutput
            $result | Should -Not -BeNullOrEmpty
        }

        It 'Should have Success = true' {
            $result = Convert-FoundryLocalUnloadOutput -Output $successOutput
            $result.Success | Should -BeTrue
        }
    }

    Context 'When output is empty' {
        It 'Should return nothing for null input' {
            $result = Convert-FoundryLocalUnloadOutput -Output $null
            $result | Should -BeNullOrEmpty
        }
    }
}

Describe 'Convert-FoundryLocalServiceStartOutput' {
    Context 'When service starts successfully' {
        BeforeAll {
            $successOutput = @('🟢 Service is Started on http://127.0.0.1:44549/, PID 12345!')
        }

        It 'Should return ServiceStartResult object' {
            $result = Convert-FoundryLocalServiceStartOutput -Output $successOutput
            $result | Should -Not -BeNullOrEmpty
        }

        It 'Should have Success = true' {
            $result = Convert-FoundryLocalServiceStartOutput -Output $successOutput
            $result.Success | Should -BeTrue
        }

        It 'Should parse Endpoint' {
            $result = Convert-FoundryLocalServiceStartOutput -Output $successOutput
            $result.Endpoint | Should -Be 'http://127.0.0.1:44549/'
        }

        It 'Should parse Port' {
            $result = Convert-FoundryLocalServiceStartOutput -Output $successOutput
            $result.Port | Should -Be 44549
        }

        It 'Should parse ProcessId' {
            $result = Convert-FoundryLocalServiceStartOutput -Output $successOutput
            $result.ProcessId | Should -Be 12345
        }
    }

    Context 'When output is empty' {
        It 'Should return nothing for null input' {
            $result = Convert-FoundryLocalServiceStartOutput -Output $null
            $result | Should -BeNullOrEmpty
        }
    }
}

Describe 'Convert-FoundryLocalServiceStopOutput' {
    Context 'When service stops successfully' {
        BeforeAll {
            $successOutput = @('🔴 Service stopped')
        }

        It 'Should return ServiceStopResult object' {
            $result = Convert-FoundryLocalServiceStopOutput -Output $successOutput
            $result | Should -Not -BeNullOrEmpty
        }

        It 'Should have Success = true' {
            $result = Convert-FoundryLocalServiceStopOutput -Output $successOutput
            $result.Success | Should -BeTrue
        }
    }

    Context 'When output is empty' {
        It 'Should return nothing for null input' {
            $result = Convert-FoundryLocalServiceStopOutput -Output $null
            $result | Should -BeNullOrEmpty
        }
    }
}

Describe 'Convert-FoundryLocalCacheRemoveOutput' {
    Context 'When model is removed successfully' {
        BeforeAll {
            $successOutput = @('Model removed from cache')
        }

        It 'Should return CacheRemoveResult object' {
            $result = Convert-FoundryLocalCacheRemoveOutput -Output $successOutput
            $result | Should -Not -BeNullOrEmpty
        }

        It 'Should have Success = true' {
            $result = Convert-FoundryLocalCacheRemoveOutput -Output $successOutput
            $result.Success | Should -BeTrue
        }
    }

    Context 'When output is empty' {
        It 'Should return nothing for null input' {
            $result = Convert-FoundryLocalCacheRemoveOutput -Output $null
            $result | Should -BeNullOrEmpty
        }
    }
}

Describe 'Convert-FoundryLocalCacheCdOutput' {
    Context 'When cache location is changed' {
        BeforeAll {
            $successOutput = @('Cache location changed to D:\FoundryCache')
        }

        It 'Should return CacheLocationChange object' {
            $result = Convert-FoundryLocalCacheCdOutput -Output $successOutput
            $result | Should -Not -BeNullOrEmpty
        }

        It 'Should have Success = true' {
            $result = Convert-FoundryLocalCacheCdOutput -Output $successOutput
            $result.Success | Should -BeTrue
        }
    }

    Context 'When path is invalid' {
        BeforeAll {
            $errorOutput = @('Error: invalid path')
        }

        It 'Should have Success = false' {
            $result = Convert-FoundryLocalCacheCdOutput -Output $errorOutput
            $result.Success | Should -BeFalse
        }
    }

    Context 'When output is empty' {
        It 'Should return nothing for null input' {
            $result = Convert-FoundryLocalCacheCdOutput -Output $null
            $result | Should -BeNullOrEmpty
        }
    }
}
