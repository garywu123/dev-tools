# Organization Requirements

## Purpose

This document defines how the `dev-tools` workspace should be organized and documented.

The workspace is a collection of independent tools. The root level should help agents and developers find the right tool quickly, while detailed behavior and design requirements should live close to the relevant tool or in shared requirement documents under `doc/`.

## Root Structure

Expected root-level structure:

```text
dev-tools/
  README.md
  AGENTS.md
  CLAUDE.md
  .github/
    copilot-instructions.md
  doc/
    organization-requirements.md
    python-tool-requirements.md
  tool-name/
    README.md
    ...
```

## Root README

The root `README.md` is the workspace index.

It should include:

- a short description of the workspace purpose
- a tool index
- links to agent instructions and general requirements

The tool index should list:

- tool name
- purpose
- primary entry point, when one exists
- local tool documentation

Update the root `README.md` whenever a top-level tool directory is added, renamed, removed, or materially repurposed.

## Tool Directories

Each tool should live in its own top-level directory.

Each tool directory should contain a `README.md` that explains:

- what the tool does
- when to use it
- required runtime or dependencies
- expected configuration files or environment variables
- common usage examples
- validation or test commands, when available
- important risks, limitations, and assumptions
- links to tool-specific design or requirement documents, if they exist

Tool-specific design documents may live in a local `doc/`, `docs/`, or `design/` directory inside the tool folder. Prefer one convention per tool, and make the tool `README.md` point to the relevant files.

## Shared Requirement Documents

Use root-level `doc/` for requirements that apply across multiple tools.

Examples:

- `doc/organization-requirements.md`: workspace layout and documentation rules
- `doc/python-tool-requirements.md`: requirements for Python-based tools

Add new shared requirement documents only when the rule is likely to apply to more than one tool.

## Documentation Principles

- Keep `AGENTS.md` thin and navigational.
- Put general rules in root-level `doc/`.
- Put tool-specific rules inside the tool directory.
- Avoid duplicating long requirements across files.
- Keep examples current and runnable.
- State assumptions explicitly, especially local paths and environment-specific configuration.

