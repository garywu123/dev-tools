# Doc Sync Workflow

This folder contains the workflow that syncs project documentation files from configured source locations into the `JBT-DMR` documentation root.

## Entry Point

- `Sync-DocWorkspace.ps1`: copies files from configured source folders or source files into the matching target folders.

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
- The script resolves the repository root from `Report_Database.code-workspace`.
- The target root can come from `TargetRoot` in the config or from the script parameter.

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

## Usage

```powershell
.\scripts\doc-sync\Sync-DocWorkspace.ps1 -WhatIf
```

The recommended VS Code task should pass the config path and, if needed, override `-TargetRoot`.
