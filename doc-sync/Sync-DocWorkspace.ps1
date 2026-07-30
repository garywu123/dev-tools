<#
.SYNOPSIS
    Synchronizes documentation files from configured source folders or files to target documentation folders.

.DESCRIPTION
    Reads a JSON configuration that lists source and destination mappings relative to the configured roots.
    The script copies all files from source folders, or one configured source file, into the target folders.
    Existing destination files are overwritten.
#>

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
param(
    [string]$ConfigPath,
    [string]$WorkspaceFilePath,
    [string]$TargetRoot,
    [string]$RepoRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

if (-not $ConfigPath) {
    $ConfigPath = Join-Path $scriptRoot 'doc-sync.config.json'
}

function Resolve-PathRelativeToBase {
    param(
        [Parameter(Mandatory = $true)]
        [string]$BasePath,
        [Parameter(Mandatory = $true)]
        [string]$RelativePath
    )

    if ([System.IO.Path]::IsPathRooted($RelativePath)) {
        return (Resolve-Path -LiteralPath $RelativePath).Path
    }

    $baseDirectory = Split-Path -Parent $BasePath
    return (Resolve-Path -LiteralPath (Join-Path $baseDirectory $RelativePath)).Path
}

function Resolve-TargetRoot {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ConfiguredTargetRoot,
        [Parameter(Mandatory = $true)]
        $Workspace,
        [Parameter(Mandatory = $true)]
        [string]$WorkspaceDirectory,
        [Parameter(Mandatory = $true)]
        [string]$ConfigPath
    )

    $workspaceFolder = $Workspace.folders | Where-Object { $_.name -eq $ConfiguredTargetRoot } | Select-Object -First 1

    if ($workspaceFolder) {
        $folderPath = [string]$workspaceFolder.path

        if ([System.IO.Path]::IsPathRooted($folderPath)) {
            return (Resolve-Path -LiteralPath $folderPath).Path
        }

        return (Resolve-Path -LiteralPath (Join-Path $WorkspaceDirectory $folderPath)).Path
    }

    if ([System.IO.Path]::IsPathRooted($ConfiguredTargetRoot)) {
        return (Resolve-Path -LiteralPath $ConfiguredTargetRoot).Path
    }

    $configDirectory = Split-Path -Parent $ConfigPath
    return (Resolve-Path -LiteralPath (Join-Path $configDirectory $ConfiguredTargetRoot)).Path
}

function Resolve-ConfiguredPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ConfiguredPath,
        [Parameter(Mandatory = $true)]
        [string[]]$BaseDirectories
    )

    if ([System.IO.Path]::IsPathRooted($ConfiguredPath)) {
        if (Test-Path -LiteralPath $ConfiguredPath) {
            return (Resolve-Path -LiteralPath $ConfiguredPath).Path
        }

        return [System.IO.Path]::GetFullPath($ConfiguredPath)
    }

    foreach ($baseDirectory in $BaseDirectories) {
        $candidatePath = [System.IO.Path]::GetFullPath((Join-Path $baseDirectory $ConfiguredPath))

        if (Test-Path -LiteralPath $candidatePath) {
            return (Resolve-Path -LiteralPath $candidatePath).Path
        }
    }

    return [System.IO.Path]::GetFullPath((Join-Path $BaseDirectories[0] $ConfiguredPath))
}

function Get-ConfiguredRoots {
    param(
        [Parameter(Mandatory = $false)]
        $ConfiguredRoots,
        [Parameter(Mandatory = $false)]
        [string]$SingleRoot,
        [Parameter(Mandatory = $true)]
        [string]$RepositoryRoot,
        [Parameter(Mandatory = $true)]
        [string]$WorkspaceDirectory,
        [Parameter(Mandatory = $true)]
        [string]$ConfigPath,
        [Parameter(Mandatory = $true)]
        [ValidateSet('Source', 'Target')]
        [string]$Kind
    )

    $roots = @{}
    $rootEntries = @()

    if ($ConfiguredRoots) {
        $rootEntries = @($ConfiguredRoots)
    }
    elseif ($SingleRoot) {
        $rootEntries = @(
            [pscustomobject]@{
                Ref  = 'default'
                Path = $SingleRoot
            }
        )
    }

    foreach ($rootEntry in $rootEntries) {
        $ref = [string]$rootEntry.Ref
        $path = [string]$rootEntry.Path

        if ([string]::IsNullOrWhiteSpace($ref)) {
            throw "$Kind root entries must define Ref."
        }

        if ([string]::IsNullOrWhiteSpace($path)) {
            throw "$Kind root entries must define Path."
        }

        $resolvedPath = if ($Kind -eq 'Source') {
            Resolve-ConfiguredPath -ConfiguredPath $path -BaseDirectories @($RepositoryRoot, (Split-Path -Parent $ConfigPath))
        }
        else {
            Resolve-ConfiguredPath -ConfiguredPath $path -BaseDirectories @($WorkspaceDirectory, (Split-Path -Parent $ConfigPath))
        }

        if ($roots.ContainsKey($ref)) {
            throw "$Kind root ref '$ref' is defined more than once."
        }

        $roots[$ref] = $resolvedPath
    }

    return $roots
}

function Resolve-RootedPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$PathValue,
        [Parameter(Mandatory = $true)]
        [hashtable]$Roots,
        [Parameter(Mandatory = $true)]
        [string]$Kind
    )

    if ([System.IO.Path]::IsPathRooted($PathValue)) {
        return [System.IO.Path]::GetFullPath($PathValue)
    }

    $ref = $null
    $relativePath = $PathValue

    if ($PathValue -match '^--(?<ref>[^\\/:]+)(?<separator>[\\/:]?)(?<rest>.*)$') {
        $ref = $Matches['ref']
        $relativePath = $Matches['rest']
    }
    elseif ($Roots.Count -gt 1) {
        throw "$Kind mapping path '$PathValue' must start with a root reference like --1\\path because multiple $Kind roots are configured."
    }
    else {
        $ref = @($Roots.Keys)[0]
    }

    if (-not $Roots.ContainsKey($ref)) {
        throw "$Kind root ref '$ref' was not found. Available refs: $(@($Roots.Keys) -join ', ')"
    }

    $basePath = [string]$Roots[$ref]

    if ([string]::IsNullOrWhiteSpace($relativePath)) {
        return $basePath
    }

    if ($relativePath.StartsWith('\') -or $relativePath.StartsWith('/')) {
        $relativePath = $relativePath.TrimStart('\', '/')
    }

    if ([string]::IsNullOrWhiteSpace($relativePath) -or $relativePath -eq '.') {
        return $basePath
    }

    return (Join-Path $basePath $relativePath)
}

function Get-RelativePath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$BasePath,
        [Parameter(Mandatory = $true)]
        [string]$ChildPath
    )

    $baseFullPath = [System.IO.Path]::GetFullPath($BasePath)
    $childFullPath = [System.IO.Path]::GetFullPath($ChildPath)

    if (-not $baseFullPath.EndsWith([System.IO.Path]::DirectorySeparatorChar)) {
        $baseFullPath = $baseFullPath + [System.IO.Path]::DirectorySeparatorChar
    }

    $baseUri = [System.Uri]::new($baseFullPath)
    $childUri = [System.Uri]::new($childFullPath)
    return [System.Uri]::UnescapeDataString($baseUri.MakeRelativeUri($childUri).ToString()).Replace('/', '\')
}

function Get-MappingStringValue {
    param(
        [Parameter(Mandatory = $true)]
        $Mapping,
        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    $property = $Mapping.PSObject.Properties[$Name]

    if (-not $property) {
        return $null
    }

    $value = [string]$property.Value

    if ([string]::IsNullOrWhiteSpace($value)) {
        return $null
    }

    return $value
}

function Get-MappingBooleanValue {
    param(
        [Parameter(Mandatory = $true)]
        $Mapping,
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [Parameter(Mandatory = $false)]
        [bool]$DefaultValue = $false
    )

    $property = $Mapping.PSObject.Properties[$Name]

    if (-not $property -or $null -eq $property.Value) {
        return $DefaultValue
    }

    return [System.Convert]::ToBoolean($property.Value)
}

function Copy-DocSyncFile {
    param(
        [Parameter(Mandatory = $true)]
        [string]$SourceFile,
        [Parameter(Mandatory = $true)]
        [string]$DestinationPath
    )

    $destinationParent = Split-Path -Parent $DestinationPath

    if (-not (Test-Path -LiteralPath $destinationParent)) {
        if ($PSCmdlet.ShouldProcess($destinationParent, 'Create directory')) {
            New-Item -ItemType Directory -Path $destinationParent -Force | Out-Null
        }
    }

    if ($PSCmdlet.ShouldProcess($DestinationPath, "Copy from $SourceFile")) {
        Copy-Item -LiteralPath $SourceFile -Destination $DestinationPath -Force
    }
}

if (-not (Test-Path -LiteralPath $ConfigPath)) {
    throw "Configuration file not found: $ConfigPath"
}

$config = Get-Content -LiteralPath $ConfigPath -Raw | ConvertFrom-Json

if (-not $TargetRoot -and $config.PSObject.Properties.Name -contains 'TargetRoot') {
    $TargetRoot = [string]$config.TargetRoot
}

$workspaceDirectory = $scriptRoot

if ($RepoRoot) {
    $repoRoot = (Resolve-Path -LiteralPath $RepoRoot).Path
}
else {
    if (-not $WorkspaceFilePath) {
        $WorkspaceFilePath = Join-Path $scriptRoot '..\..\Report_Database.code-workspace'
    }

    if (-not (Test-Path -LiteralPath $WorkspaceFilePath)) {
        throw "Workspace file not found: $WorkspaceFilePath. Provide -RepoRoot to skip workspace file lookup."
    }

    $workspace = Get-Content -LiteralPath $WorkspaceFilePath -Raw | ConvertFrom-Json
    $repoFolder = $workspace.folders | Where-Object { $_.name -eq 'JBT_DualMode_Report_Database' } | Select-Object -First 1

    if (-not $repoFolder) {
        throw "Workspace folder named 'JBT_DualMode_Report_Database' was not found in $WorkspaceFilePath. Provide -RepoRoot to skip workspace file lookup."
    }

    $workspaceDirectory = Split-Path -Parent $WorkspaceFilePath
    $repoRoot = [string]$repoFolder.path

    if ([System.IO.Path]::IsPathRooted($repoRoot)) {
        $repoRoot = (Resolve-Path -LiteralPath $repoRoot).Path
    }
    else {
        $repoRoot = (Resolve-Path -LiteralPath (Join-Path $workspaceDirectory $repoRoot)).Path
    }
}

$legacySourceRoot = if ($config.PSObject.Properties.Name -contains 'SourceRoot') { [string]$config.SourceRoot } else { $null }
$legacyTargetRoot = if ($config.PSObject.Properties.Name -contains 'TargetRoot') { [string]$config.TargetRoot } else { $null }

$sourceRoots = Get-ConfiguredRoots -ConfiguredRoots $config.SourceRoots -SingleRoot $legacySourceRoot -RepositoryRoot $repoRoot -WorkspaceDirectory $workspaceDirectory -ConfigPath $ConfigPath -Kind 'Source'
$targetRoots = Get-ConfiguredRoots -ConfiguredRoots $config.TargetRoots -SingleRoot $legacyTargetRoot -RepositoryRoot $repoRoot -WorkspaceDirectory $workspaceDirectory -ConfigPath $ConfigPath -Kind 'Target'

if ($sourceRoots.Count -eq 0) {
    throw 'Configuration must define at least one source root.'
}

if ($targetRoots.Count -eq 0) {
    throw 'Configuration must define at least one target root.'
}

$mappings = @($config.Mappings)

if ($mappings.Count -eq 0) {
    throw 'Configuration must define at least one mapping in Mappings.'
}

foreach ($mapping in $mappings) {
    $sourceDirValue = Get-MappingStringValue -Mapping $mapping -Name 'SourceDir'
    $sourceFileValue = Get-MappingStringValue -Mapping $mapping -Name 'SourceFile'
    $destinationDirValue = Get-MappingStringValue -Mapping $mapping -Name 'DestinationDir'
    $includeSubfolders = Get-MappingBooleanValue -Mapping $mapping -Name 'IncludeSubfolders' -DefaultValue $false

    if ($sourceDirValue -and $sourceFileValue) {
        throw 'Each mapping must define either SourceDir or SourceFile, not both.'
    }

    if (-not $sourceDirValue -and -not $sourceFileValue) {
        throw 'Each mapping must define either SourceDir or SourceFile.'
    }

    if (-not $destinationDirValue) {
        throw 'Each mapping must define DestinationDir.'
    }

    $destinationDirectoryRoot = Resolve-RootedPath -PathValue $destinationDirValue -Roots $targetRoots -Kind 'Target'

    if (-not (Test-Path -LiteralPath $destinationDirectoryRoot)) {
        if ($PSCmdlet.ShouldProcess($destinationDirectoryRoot, 'Create directory')) {
            New-Item -ItemType Directory -Path $destinationDirectoryRoot -Force | Out-Null
        }
    }

    if ($sourceFileValue) {
        $sourceFile = Resolve-RootedPath -PathValue $sourceFileValue -Roots $sourceRoots -Kind 'Source'

        if (-not (Test-Path -LiteralPath $sourceFile -PathType Leaf)) {
            throw "Source file not found: $sourceFile"
        }

        $destinationPath = Join-Path $destinationDirectoryRoot (Split-Path -Leaf $sourceFile)
        Copy-DocSyncFile -SourceFile $sourceFile -DestinationPath $destinationPath
        continue
    }

    $sourceDirectory = Resolve-RootedPath -PathValue $sourceDirValue -Roots $sourceRoots -Kind 'Source'

    if (-not (Test-Path -LiteralPath $sourceDirectory -PathType Container)) {
        throw "Source directory not found: $sourceDirectory"
    }

    $childItemParameters = @{
        LiteralPath = $sourceDirectory
        File = $true
    }

    if ($includeSubfolders) {
        $childItemParameters.Recurse = $true
    }

    $files = Get-ChildItem @childItemParameters

    foreach ($file in $files) {
        $relativePath = Get-RelativePath -BasePath $sourceDirectory -ChildPath $file.FullName
        $destinationPath = Join-Path $destinationDirectoryRoot $relativePath
        Copy-DocSyncFile -SourceFile $file.FullName -DestinationPath $destinationPath
    }
}

Write-Host "Processed $($mappings.Count) mapping(s) from $repoRoot using $($sourceRoots.Count) source root(s) and $($targetRoots.Count) target root(s)."
