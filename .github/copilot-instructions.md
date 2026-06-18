# Copilot Instructions

This workspace is a collection of small development and operations tools used across local projects.

Keep this file as navigation guidance. Detailed requirements belong in root-level `doc/` files or in a specific tool's own documentation.

## Navigation

When working in this workspace:

1. Start with the root `README.md` to identify the relevant tool directory.
2. Read the selected tool's local `README.md` before changing or running that tool.
3. Follow shared requirements from `doc/`.
4. Follow any tool-specific design or requirement documents referenced by the tool README.

## Shared Requirements

- Workspace and documentation organization: `doc/organization-requirements.md`
- Python tool requirements: `doc/python-tool-requirements.md`

## Working Expectations

- Make the smallest effective change that solves the problem.
- Prefer clear, focused tools over unnecessary framework or abstraction.
- Keep secrets, credentials, machine-specific tokens, and private connection strings out of the repository.
- Run the relevant validation for the touched tool when practical.
- If validation cannot be run, state why and describe the remaining risk.

