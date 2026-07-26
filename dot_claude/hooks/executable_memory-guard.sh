#!/usr/bin/env bash
# SessionStart hook: audit the effective Git-root auto-memory destination.
# The Node doctor consumes the hook JSON from stdin and stays silent when healthy.

set -u

doctor="${HOME}/.local/bin/claude-memory-doctor"
if [ ! -x "$doctor" ]; then
  exit 0
fi

exec "$doctor" --hook
