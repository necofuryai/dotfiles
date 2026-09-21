# Git Workflow

- Commit messages and PR titles: Conventional Commits `<type>: <description>` plus an optional body. Types: feat, fix, refactor, docs, test, chore, perf, ci.
- Commit messages and PR titles MUST be in English, even when the session language is Japanese. PR bodies may be in Japanese.
- PRs: analyze the full commit history, not just the latest commit — `git diff [base-branch]...HEAD`. Draft a comprehensive summary with a test plan (TODOs). Push with `-u` if the branch is new.
