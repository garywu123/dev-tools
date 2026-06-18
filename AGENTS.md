# Developer Tools Workspace

## Purpose

This workspace is a collection of small development and operations tools used across local projects.

Tools may include PowerShell scripts, Python scripts, SQL deployment helpers, directory synchronization utilities, documentation synchronization workflows, and other repeatable developer automation.

Keep this file as navigation guidance. Detailed design and structure rules belong in `doc/` or in a specific tool's own documentation.

## Navigation Order

When working in this workspace:

1. Start with the root `README.md` to identify the relevant tool directory.
2. Read the selected tool's local `README.md` before changing or running that tool.
3. Follow general workspace requirements from `doc/`.
4. Follow tool-specific design or requirement documents referenced by the tool's own `README.md`.

## General Requirements

- Workspace and documentation organization: `doc/organization-requirements.md`
- Python tool requirements: `doc/python-tool-requirements.md`

## Working Expectations

- Make the smallest effective change that solves the problem.
- Prefer clear, focused tools over unnecessary framework or abstraction.
- Keep secrets, credentials, machine-specific tokens, and private connection strings out of the repository.
- Before claiming a change is complete, run the relevant validation for the touched tool when practical.
- If validation cannot be run, state why and describe the remaining risk.

