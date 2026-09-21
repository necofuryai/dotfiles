# Mise runtime and ownership branch

Read this reference only when installing or removing a runtime, changing the canonical manager, or diagnosing why a command resolves to an unexpected version.

## Prove ownership before changing it

Capture:

- `command -v <command>` and resolved symlink targets;
- `mise which <command>`, `mise which <command> --version`, and `mise where <tool>` when applicable;
- global and repository mise declarations plus language-native version files;
- other managers that may own the runtime, such as rustup, Homebrew, uv, or a project-local environment;
- active processes and open files before removal.

Distinguish the manager binary, the selected runtime, shims, caches, project pins, and the effective executable. A successful version command proves only the last of these.

## Change narrowly

- Add or update the declaration at the layer that is meant to own the version.
- Open a fresh login shell before judging PATH or activation changes.
- Use the manager's narrow dry run or diagnostic when available.
- Runtime removal requires explicit authorization after the use, pin, process, and symlink checks. `mise uninstall` removes the installed runtime or cache; it does not remove stale declarations from configuration files.
- Manager migration must leave one declared owner and must verify project-specific overrides separately.

Report the previous owner and version, changed declaration, resulting executable path and version, remaining pins, and any restart or fresh-shell limitation.
