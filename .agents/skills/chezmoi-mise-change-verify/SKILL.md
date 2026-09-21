---
name: chezmoi-mise-change-verify
description: Change or verify chezmoi-managed targets and mise-owned declarations, runtime selection, executable resolution, or manager migrations when source, rendered, live, and effective state may differ. Includes explicitly requested runtime install or removal; excludes generic repository config and routine package upgrades.
---

# Chezmoi Mise Change Verify

Move one intended change through the full chain from authoritative source to observed effect without importing unrelated live state.

## Route the request

- **Verify-only:** inspect and report the source, generated or rendered state, live target, effective resolver, and drift. Do not edit, import, apply, stage, install, remove, commit, or push.
- **Change:** edit only the authoritative layer named or implied by the request. Treat import, targeted apply, staging, install or removal, commit, and push as separate transitions; perform only those covered by the request.

If the intended terminal state is unclear and would change a live file, runtime, or Git state, finish the read-only diagnosis and stop at that boundary.

For a chezmoi-managed coding-agent setting, this skill owns source -> rendered -> live reconciliation. Before or after any change, use `ai-agent-effective-config-audit` for documented -> configured -> loaded/effective -> observed behavior. A live transition remains governed only by this skill's explicit change and apply boundaries; neither skill expands the other's authorization.

## 1. Resolve the state chain

- Read the source repository's current `AGENTS.md` or `CLAUDE.md` before changing anything.
- Inspect `git status --short --renames`, then resolve each target with `chezmoi source-path <target>`.
- Classify every relevant layer as **source**, **generated or rendered**, **live target**, and **effective state**. Record which layer is authoritative.
- Detect templates and generated files before editing. Compare source, rendered output, live content, and history when they disagree; do not treat `chezmoi re-add` as an automatic merge.
- For a mise-managed command, establish ownership with `mise which`, `mise where`, `mise ls --current`, project version files, shell resolution, and relevant symlinks. Before removing a runtime, also inspect active processes and open files.
- Separate the requested authority for source edits, targeted apply, install or removal, commit, and push. One does not imply another.

Proceed when the intended source, target, effective resolver, existing drift, and authorized state transitions are explicit.

## 2. Change the authoritative layer

- Edit the chezmoi source rather than the live target. Preserve portable templates and keep credentials or machine-private values out of a public source repository.
- When the request explicitly includes changing the state that owns a generated target, regenerate it through that owning command. Import only the named target with `chezmoi add <target>` when that import is also in scope; otherwise report the generated/live difference without importing it. Do not hand-edit the generated source copy.
- Change mise declarations at the owning global or project layer. Preserve another manager's ownership unless the task explicitly authorizes a migration.
- Preview a narrowly targeted apply for a change request. Run `chezmoi apply <target>` only when applying the live change is part of the request.
- If apply is outside the request, stop at a verified source change and report `source updated; live target not applied`.

For shell helpers or Brewfile behavior, read [references/shell-and-brewfile.md](references/shell-and-brewfile.md). For runtime removal or manager migration, read [references/mise-runtime.md](references/mise-runtime.md).

## 3. Verify every changed layer

- Review `chezmoi diff --no-pager <target>` and inspect `chezmoi status` for unrelated drift. Run `chezmoi verify <target>` to test current agreement in verify-only mode or after an authorized apply; exit status `1` is observed drift, not permission to reconcile it.
- Validate the changed format or program: parse JSON/TOML, check shell syntax and fresh startup, or run the narrow tool-specific diagnostic.
- Re-resolve the effective executable or setting in a fresh process when activation, PATH, reload, or restart affects the result.
- Run `git diff --check` and inspect the intended diff for credentials, personal absolute paths, generated-file mistakes, and unrelated managed targets.
- Treat sandbox, cache, state-database, or non-TTY failures as execution-context evidence until reproduced in the intended environment.

The change is complete only when the authoritative source is correct and every downstream layer included in the request is verified. A downstream layer outside the request may be reported as intentionally unapplied. If an authorized required layer cannot be changed or verified, report the outcome as blocked or incomplete rather than complete with an unresolved layer.

## Handoff

Report the source path, live target, effective resolver, changed files, apply status, validation results, remaining drift, and any separately authorized Git or removal action. Never report source, apply, commit, or push as interchangeable states.
