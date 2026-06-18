# Developer Tools

This repository contains small development and operations tools used across local projects.

The goal is to keep common automation in one place, with each tool documented and easy to run independently.

## Tool Index

| Tool | Purpose | Entry Point | Documentation |
| --- | --- | --- | --- |
| `doc-sync` | Synchronizes configured documentation folders or files into configured target documentation folders. | `doc-sync/Sync-DocWorkspace.ps1` | `doc-sync/README.md` |

## Repository Conventions

- Each top-level tool directory should contain a `README.md`.
- The root `README.md` should be updated when tools are added, renamed, or removed.
- Tool-specific usage belongs in the tool directory, not in this index.
- Tools that modify files, deploy artifacts, or overwrite output should support preview behavior when practical.

## General Requirements

- Workspace and documentation organization: `doc/organization-requirements.md`
- Python tool requirements: `doc/python-tool-requirements.md`

## Agent Instructions

- General agent instructions are in `AGENTS.md`.
- Claude-specific instructions are in `CLAUDE.md`.
- GitHub Copilot instructions are in `.github/copilot-instructions.md`.
