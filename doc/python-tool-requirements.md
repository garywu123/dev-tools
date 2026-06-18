# Python Tool Requirements

## Purpose

This document defines default expectations for Python-based tools in this workspace.

These requirements apply when creating or modifying a tool whose primary implementation is Python. Tool-specific requirements may add stricter rules, but should not silently contradict this document.

## Environment

- Use a virtual environment by default.
- Prefer a local `.venv` directory inside the tool folder unless the tool README states another location.
- Document the Python version expected by the tool.
- Document the commands to create and activate the virtual environment.

Recommended setup example:

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install --upgrade pip
```

## Dependencies

- Prefer the Python standard library.
- Add a third-party dependency only when it materially improves correctness, maintainability, or implementation cost.
- Prefer mature, popular, actively maintained open-source libraries.
- Avoid obscure dependencies for small scripts unless there is a clear technical reason.
- Keep dependency scope narrow; do not add a framework for a simple utility.

For simple tools, use `requirements.txt`.

Use `pyproject.toml` when the tool needs packaging metadata, build configuration, console scripts, or multiple development dependency groups.

The tool README should explain how to install dependencies, for example:

```powershell
python -m pip install -r requirements.txt
```

## Layout

Keep Python tools small and easy to inspect.

For a simple single-purpose tool:

```text
tool-name/
  README.md
  main.py
  requirements.txt
  tests/
    ...
```

For a tool with multiple modules:

```text
tool-name/
  README.md
  requirements.txt
  src/
    tool_name/
      __init__.py
      main.py
  tests/
    ...
```

Prefer the simple layout until the tool needs multiple modules.

## Configuration

- Prefer explicit command-line arguments for user-selected paths, modes, and targets.
- Use configuration files when repeated runs need stable mappings or settings.
- Document every configuration field in the tool README.
- Do not hard-code machine-specific paths unless the tool is explicitly local-only and the README says so.
- Do not store secrets, credentials, tokens, or private connection strings in the repository.

## Behavior

- Keep tool behavior predictable and repeatable.
- Print enough progress information to understand what the tool is doing.
- Return a non-zero exit code when the tool fails.
- Use clear error messages that identify the failed input, path, or operation.
- For tools that write files, deploy artifacts, delete data, or overwrite output, provide a preview, dry-run, or confirmation mode when practical.

## Testing and Validation

- Prefer focused tests for parsing, path resolution, transformation logic, and failure cases.
- Keep tests local to the tool directory unless a shared test structure is later introduced.
- Document the validation command in the tool README.

Common examples:

```powershell
python -m unittest discover
```

```powershell
python -m pytest
```

Use `pytest` only when its features materially improve the test suite. For very small tools, `unittest` from the standard library is usually sufficient.

## Tool README Requirements

Each Python tool README should include:

- purpose
- requirements
- virtual environment setup
- dependency installation
- configuration
- usage examples
- validation command
- known risks or limitations

