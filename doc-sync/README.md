# Doc Sync Workflow

This folder contains the workflow that syncs project documentation files from configured source locations to a configured destination (typically Obsidian).

## Entry Points

- `Sync-DocWorkspace.ps1`: copies files from configured source folders or source files into the matching target folders.
- `New-DocSyncProjectSetup.ps1`: one-shot setup script that creates `doc-sync.config.json` and `.vscode/tasks.json` for a new project.

## Setting Up a New Project

Run the setup script from any terminal, passing only the two paths that vary per project:

```powershell
D:\code\lib-projects\dev-tools\doc-sync\New-DocSyncProjectSetup.ps1 `
    -ProjectDir "D:\code\work-projects\my-project" `
    -DocDestDir "C:\Users\garyw\OneDrive\MarkdownNotes\MyProject"
```

The script:
- Creates `doc-sync.config.json` at the project root (uses `<ProjectDir>\doc` as the source unless you pass `-DocSourceDir`).
- Creates or merges `.vscode/tasks.json` with **Doc Sync: Sync docs to Obsidian** and **Doc Sync: Preview (WhatIf)** tasks.
- Never overwrites existing tasks entries; it merges missing ones.

Use `-WhatIf` to preview what would be created/changed without writing anything.

## Configuration

- `doc-sync.config.json` stores source-to-destination mappings.
- Each mapping defines:
  - `SourceDir`: source folder relative to a configured source root.
  - `SourceFile`: source file relative to a configured source root.
  - `DestinationDir`: target folder relative to the documentation root.
- A mapping must define exactly one of `SourceDir` or `SourceFile`.
- `IncludeSubfolders` is optional and defaults to `false`.
  - `false`: `SourceDir` copies only files directly inside that folder.
  - `true`: `SourceDir` copies files recursively and preserves subfolder paths.
- `SourceFile` copies that single file into `DestinationDir` using the same file name.
- For multi-root setups, define `SourceRoots` and `TargetRoots` as arrays of objects with `Ref` and `Path`.
- Use the `--<ref>\path` form inside `SourceDir` and `DestinationDir` to choose a root by reference.
- Example: `--1\\Report DB Design\\Fact` means "use source root ref `1`, then go into `Report DB Design\Fact`".
- If only one root is configured for a side, the script also accepts plain relative paths without a `--ref` prefix.
- The target root can come from `TargetRoot` in the config or from the `-TargetRoot` script parameter.

## Behavior

- For `SourceDir`, the script scans only the current folder by default.
- Set `IncludeSubfolders` to `true` to scan recursively.
- It copies all file types, including Markdown, PDFs, images, and other attachments.
- It preserves relative paths within each recursive source folder.
- For `SourceFile`, it copies only the configured file and preserves the file name.
- Use `-WhatIf` to preview file operations before copying.

## Mapping Examples

Copy files directly inside a folder only:

```json
{
  "SourceDir": "--1\\Report DB Design\\Fact",
  "DestinationDir": "--1\\Report DB Design\\Fact"
}
```

Copy a folder recursively:

```json
{
  "SourceDir": "--1\\Report DB Design\\Fact",
  "DestinationDir": "--1\\Report DB Design\\Fact",
  "IncludeSubfolders": true
}
```

Copy one file:

```json
{
  "SourceFile": "--1\\Report DB Design\\Fact\\example.md",
  "DestinationDir": "--1\\Report DB Design\\Fact"
}
```

## Script Parameters

`Sync-DocWorkspace.ps1` accepts:

| Parameter           | Required | Description |
|---------------------|----------|-------------|
| `-ConfigPath`       | No       | Path to the config file. Defaults to `doc-sync.config.json` in the script folder. |
| `-RepoRoot`         | No       | Absolute path to the project root. When provided, bypasses the workspace file lookup. Use this for projects that are not part of the SGVM workspace. |
| `-WorkspaceFilePath`| No       | Path to a `.code-workspace` file. Used only when `-RepoRoot` is not provided (legacy SGVM support). |
| `-TargetRoot`       | No       | Overrides the target root from the config. |
| `-WhatIf`           | No       | Preview operations without copying any files. |

## Usage

```powershell
# SGVM project (legacy - resolves root from workspace file)
.\Sync-DocWorkspace.ps1 -WhatIf

# Any other project (pass -RepoRoot to bypass workspace lookup)
.\Sync-DocWorkspace.ps1 `
    -ConfigPath "D:\code\work-projects\my-project\doc-sync.config.json" `
    -RepoRoot "D:\code\work-projects\my-project" `
    -WhatIf
```

The recommended VS Code task should pass `-ConfigPath` and `-RepoRoot` explicitly.
