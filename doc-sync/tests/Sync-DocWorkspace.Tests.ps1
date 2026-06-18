[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:TestRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("doc-sync-tests-" + [System.Guid]::NewGuid().ToString('N'))
$script:RepoRoot = Join-Path $script:TestRoot 'repo'
$script:SourceRoot = Join-Path $script:TestRoot 'source'
$script:TargetRoot = Join-Path $script:TestRoot 'target'
$script:WorkspacePath = Join-Path $script:TestRoot 'test.code-workspace'
$script:ConfigPath = Join-Path $script:TestRoot 'doc-sync.config.json'
$script:ScriptUnderTest = Join-Path $PSScriptRoot '..\Sync-DocWorkspace.ps1'

function Assert-PathExists {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        throw "Expected path to exist: $Path"
    }
}

function Assert-PathMissing {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    if (Test-Path -LiteralPath $Path) {
        throw "Expected path to be missing: $Path"
    }
}

function New-TestFile {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        [Parameter(Mandatory = $true)]
        [string]$Content
    )

    $parent = Split-Path -Parent $Path
    New-Item -ItemType Directory -Path $parent -Force | Out-Null
    Set-Content -LiteralPath $Path -Value $Content -NoNewline
}

function Reset-TestDirectories {
    if (Test-Path -LiteralPath $script:TestRoot) {
        Remove-Item -LiteralPath $script:TestRoot -Recurse -Force
    }

    New-Item -ItemType Directory -Path $script:RepoRoot -Force | Out-Null
    New-Item -ItemType Directory -Path $script:SourceRoot -Force | Out-Null
    New-Item -ItemType Directory -Path $script:TargetRoot -Force | Out-Null

    $workspace = @{
        folders = @(
            @{
                name = 'JBT_DualMode_Report_Database'
                path = $script:RepoRoot
            }
        )
    }

    $workspace | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $script:WorkspacePath
}

function Write-TestConfig {
    param(
        [Parameter(Mandatory = $true)]
        [object[]]$Mappings
    )

    $config = @{
        SourceRoots = @(
            @{
                Ref = '1'
                Path = $script:SourceRoot
            }
        )
        TargetRoots = @(
            @{
                Ref = '1'
                Path = $script:TargetRoot
            }
        )
        Mappings = $Mappings
    }

    $config | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $script:ConfigPath
}

function Invoke-DocSync {
    & $script:ScriptUnderTest -ConfigPath $script:ConfigPath -WorkspaceFilePath $script:WorkspacePath
}

try {
    Reset-TestDirectories
    New-TestFile -Path (Join-Path $script:SourceRoot 'docs\root.md') -Content 'root markdown'
    New-TestFile -Path (Join-Path $script:SourceRoot 'docs\diagram.pdf') -Content 'pdf content'
    New-TestFile -Path (Join-Path $script:SourceRoot 'docs\nested\nested.md') -Content 'nested markdown'
    Write-TestConfig -Mappings @(
        @{
            SourceDir = '--1\docs'
            DestinationDir = '--1\docs-copy'
        }
    )

    Invoke-DocSync

    Assert-PathExists -Path (Join-Path $script:TargetRoot 'docs-copy\root.md')
    Assert-PathExists -Path (Join-Path $script:TargetRoot 'docs-copy\diagram.pdf')
    Assert-PathMissing -Path (Join-Path $script:TargetRoot 'docs-copy\nested\nested.md')

    Reset-TestDirectories
    New-TestFile -Path (Join-Path $script:SourceRoot 'docs\root.md') -Content 'root markdown'
    New-TestFile -Path (Join-Path $script:SourceRoot 'docs\nested\nested.md') -Content 'nested markdown'
    New-TestFile -Path (Join-Path $script:SourceRoot 'docs\nested\image.bmp') -Content 'bitmap content'
    Write-TestConfig -Mappings @(
        @{
            SourceDir = '--1\docs'
            DestinationDir = '--1\docs-copy'
            IncludeSubfolders = $true
        }
    )

    Invoke-DocSync

    Assert-PathExists -Path (Join-Path $script:TargetRoot 'docs-copy\root.md')
    Assert-PathExists -Path (Join-Path $script:TargetRoot 'docs-copy\nested\nested.md')
    Assert-PathExists -Path (Join-Path $script:TargetRoot 'docs-copy\nested\image.bmp')

    Reset-TestDirectories
    New-TestFile -Path (Join-Path $script:SourceRoot 'docs\single.md') -Content 'single markdown'
    Write-TestConfig -Mappings @(
        @{
            SourceFile = '--1\docs\single.md'
            DestinationDir = '--1\single-copy'
        }
    )

    Invoke-DocSync

    Assert-PathExists -Path (Join-Path $script:TargetRoot 'single-copy\single.md')

    Write-Host 'All doc sync tests passed.'
}
finally {
    if (Test-Path -LiteralPath $script:TestRoot) {
        Remove-Item -LiteralPath $script:TestRoot -Recurse -Force
    }
}
