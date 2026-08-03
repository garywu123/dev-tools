<#
.SYNOPSIS
    Initializes doc-sync configuration and VS Code tasks for a new project.

.DESCRIPTION
    Creates doc-sync.config.json and .vscode/tasks.json in the target project folder,
    wired to the shared Sync-DocWorkspace.ps1 script in the dev-tools repo.

.PARAMETER ProjectDir
    Root directory of the project to configure. Defaults to current directory.

.PARAMETER DocSourceDir
    Absolute path to the folder containing documentation files to sync.
    Defaults to <ProjectDir>\doc.

.PARAMETER DocDestDir
    Absolute path to the destination folder in Obsidian (or any target location).

.PARAMETER Force
    Overwrite existing doc-sync.config.json if it already exists.

.EXAMPLE
    .\New-DocSyncProjectSetup.ps1 `
        -ProjectDir "D:\code\work-projects\my-project" `
        -DocDestDir "C:\Users\garyw\OneDrive\MarkdownNotes\MyProject"

.EXAMPLE
    .\New-DocSyncProjectSetup.ps1 `
        -DocSourceDir "D:\code\work-projects\my-project\docs" `
        -DocDestDir "C:\Users\garyw\OneDrive\MarkdownNotes\MyProject\docs"
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [string]$ProjectDir = (Get-Location).Path,
    [string]$DocSourceDir,
    [Parameter(Mandatory = $true)]
    [string]$DocDestDir,
    [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$syncScript = Join-Path $scriptDir 'Sync-DocWorkspace.ps1'

# --- Resolve ProjectDir ---

$ProjectDir = (Resolve-Path -LiteralPath $ProjectDir).Path

# --- Resolve DocSourceDir ---

if (-not $DocSourceDir) {
    $DocSourceDir = Join-Path $ProjectDir 'doc'
}

if (-not [System.IO.Path]::IsPathRooted($DocSourceDir)) {
    $DocSourceDir = Join-Path $ProjectDir $DocSourceDir
}

$DocSourceDir = [System.IO.Path]::GetFullPath($DocSourceDir)

# --- Validate sync script exists ---

if (-not (Test-Path -LiteralPath $syncScript)) {
    throw "Sync-DocWorkspace.ps1 not found at: $syncScript"
}

# --- Write doc-sync.config.json ---

$configPath = Join-Path $ProjectDir 'doc-sync.config.json'

if ((Test-Path -LiteralPath $configPath) -and -not $Force) {
    Write-Warning "doc-sync.config.json already exists at $configPath. Use -Force to overwrite."
}
else {
    $config = [ordered]@{
        SourceRoots = @(
            [ordered]@{ Ref = '1'; Path = $DocSourceDir }
        )
        TargetRoots = @(
            [ordered]@{ Ref = '1'; Path = $DocDestDir }
        )
        Mappings    = @(
            [ordered]@{
                SourceDir         = '--1'
                DestinationDir    = '--1'
                IncludeSubfolders = $true
            }
        )
    }

    $configJson = $config | ConvertTo-Json -Depth 5

    if ($PSCmdlet.ShouldProcess($configPath, 'Write doc-sync.config.json')) {
        Set-Content -LiteralPath $configPath -Value $configJson -Encoding UTF8
        Write-Host "Created: $configPath"
    }
}

# --- Write .vscode/tasks.json ---

$vscodePath = Join-Path $ProjectDir '.vscode'
$tasksPath  = Join-Path $vscodePath 'tasks.json'

$syncScriptEscaped = $syncScript -replace '\\', '\\\\'

$newTasks = @(
    [ordered]@{
        label       = 'Doc Sync: Sync docs to Obsidian'
        type        = 'shell'
        command     = 'powershell'
        args        = @(
            '-ExecutionPolicy', 'Bypass',
            '-File', $syncScript,
            '-ConfigPath', '${workspaceFolder}\doc-sync.config.json',
            '-RepoRoot', '${workspaceFolder}'
        )
        presentation = [ordered]@{ reveal = 'always'; panel = 'dedicated' }
        problemMatcher = @()
    },
    [ordered]@{
        label       = 'Doc Sync: Preview (WhatIf)'
        type        = 'shell'
        command     = 'powershell'
        args        = @(
            '-ExecutionPolicy', 'Bypass',
            '-File', $syncScript,
            '-ConfigPath', '${workspaceFolder}\doc-sync.config.json',
            '-RepoRoot', '${workspaceFolder}',
            '-WhatIf'
        )
        presentation = [ordered]@{ reveal = 'always'; panel = 'dedicated' }
        problemMatcher = @()
    }
)

if (Test-Path -LiteralPath $tasksPath) {
    # Merge: add only missing tasks, leave existing ones alone.
    # tasks.json is JSONC (allows // comments); strip full-line comments so ConvertFrom-Json can parse it.
    $rawTasksJson = Get-Content -LiteralPath $tasksPath -Raw
    $strippedTasksJson = ($rawTasksJson -split "`r?`n" | Where-Object { $_.Trim() -notmatch '^//' }) -join "`n"
    $existing = $strippedTasksJson | ConvertFrom-Json
    $existingLabels = @($existing.tasks | ForEach-Object { $_.label })

    $toAdd = $newTasks | Where-Object { $_['label'] -notin $existingLabels }

    if ($toAdd.Count -eq 0) {
        Write-Host "tasks.json already contains Doc Sync tasks. No changes made to: $tasksPath"
    }
    else {
        $mergedTasks = @($existing.tasks) + @($toAdd)
        $merged = [ordered]@{ version = [string]$existing.version; tasks = $mergedTasks }
        $mergedJson = $merged | ConvertTo-Json -Depth 10

        if ($PSCmdlet.ShouldProcess($tasksPath, 'Merge Doc Sync tasks into existing tasks.json')) {
            Set-Content -LiteralPath $tasksPath -Value $mergedJson -Encoding UTF8
            Write-Host "Updated: $tasksPath (added $($toAdd.Count) task(s))"
        }
    }
}
else {
    if (-not (Test-Path -LiteralPath $vscodePath)) {
        if ($PSCmdlet.ShouldProcess($vscodePath, 'Create .vscode directory')) {
            New-Item -ItemType Directory -Path $vscodePath | Out-Null
        }
    }

    $tasksFile = [ordered]@{ version = '2.0.0'; tasks = $newTasks }
    $tasksJson = $tasksFile | ConvertTo-Json -Depth 10

    if ($PSCmdlet.ShouldProcess($tasksPath, 'Write .vscode/tasks.json')) {
        Set-Content -LiteralPath $tasksPath -Value $tasksJson -Encoding UTF8
        Write-Host "Created: $tasksPath"
    }
}

Write-Host ""
Write-Host "Doc sync setup complete for: $ProjectDir"
Write-Host "  Source : $DocSourceDir"
Write-Host "  Dest   : $DocDestDir"
Write-Host ""
Write-Host "Run 'Doc Sync: Preview (WhatIf)' from VS Code Tasks to verify before syncing."
