# Git Workflow

- Commit messages and PR titles: Conventional Commits `<type>: <description>` plus an optional body. Types: feat, fix, refactor, docs, test, chore, perf, ci.
- Commit messages and PR titles MUST be in English, even when the session language is Japanese. PR bodies may be in Japanese.
- PRs: analyze the full commit history, not just the latest commit — `git diff [base-branch]...HEAD`. Draft a comprehensive summary with a test plan (TODOs).
- Push a new branch with `git push -u origin <branch>` from a session opened in that repository, as a command line made only of bare `git …` commands (`git add … && git push -u origin <branch>` qualifies); that runs outside the sandbox.
- `git -C`/`-c`, a non-git command in the same line, a pipe, an output redirection such as `> file` or `> /dev/null` (a trailing `2>&1` alone is fine), an env prefix, or `cd` to another directory make the command run inside the sandbox, where the session's own repositories have a read-only `.git/config`. There, `-u` (and a bare `git push` under `push.autoSetupRemote`) pushes but cannot record the upstream, and git still exits 0. Push with `git push origin <branch>` (no `-u`) instead, and open the PR with `gh pr create --head <branch>` (`--head <owner>:<branch>` when the branch lives on a fork; add `-R <owner>/<repo>` from a session opened elsewhere).
