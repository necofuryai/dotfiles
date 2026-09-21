# Shell and Brewfile branch

Read this reference only for chezmoi-managed shell functions, `.zshrc`, or Brewfile generation and staging.

## Establish the loaded definition

- Resolve the source with `chezmoi source-path ~/.zshrc`.
- Inspect the current shell definition with `whence -v <function>` and `typeset -f <function>`.
- In verify-only mode, compare these layers without changing them. In change mode, edit the source file; apply only the named target when apply is in scope, then verify in a fresh interactive shell.

Useful checks are:

```sh
zsh -n ~/.zshrc
zsh -i -c exit
chezmoi diff --no-pager ~/.zshrc
chezmoi verify ~/.zshrc
```

## Preserve generated Brewfile ownership

When the current repository instructions or generator establish that `dot_Brewfile` is generated from live package state, treat that current evidence as authoritative; do not assume the rule in another chezmoi repository. In verify-only mode, compare it without regenerating, importing, or staging. When the request authorizes changing the installed package set, use the authorized package workflow and regenerate the live `~/.Brewfile`. Import that target only when import is in scope:

```sh
chezmoi add ~/.Brewfile
brewfile_source="$(chezmoi source-path ~/.Brewfile)"
```

Stage the resolved source with `chezmoi git -- add -- "$brewfile_source"` only when staging is explicitly requested.

Do not run a real upgrade merely to validate shell logic. Prefer syntax, fresh-shell, source/target diff, and status checks.

`git diff --quiet` returns `1` for ordinary differences. When shell logic needs to detect a staged Brewfile, inspect `chezmoi git -- diff --cached --name-only -- "$brewfile_source"` and branch on non-empty output while propagating genuine command errors. Test the stage-present, no-difference, and real-error paths without running the package-upgrade workflow.
