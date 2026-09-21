#!/usr/bin/env node
// Claude Code statusline: model | current task | directory | git branch/changes | context usage
//
// Derived from hooks/gsd-statusline.js in get-shit-done (GSD edition v1.30.0).
// Upstream: https://github.com/gsd-build/get-shit-done
//
// SPDX-License-Identifier: MIT
//
// MIT License
//
// Copyright (c) 2025 Lex Christopherson
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
//
// This file is under the MIT License above. It is NOT covered by the Unlicense
// dedication that applies to the rest of this repository — see
// THIRD-PARTY-LICENSES.md at the repository root.
//
// Local changes: removed the GSD update-check banner and the context-monitor
// bridge file (only meaningful inside a GSD-managed project); added the git
// segment; pinned AUTO_COMPACT_BUFFER_PCT instead of reading it from GSD config.

const fs = require('fs');
const path = require('path');
const os = require('os');
const { execFileSync } = require('child_process');

function git(args, cwd) {
  return execFileSync('git', args, { cwd, timeout: 800, stdio: ['ignore', 'pipe', 'ignore'] })
    .toString().trim();
}

let input = '';
// Exit silently if stdin never closes (pipe issues) instead of hanging.
const stdinTimeout = setTimeout(() => process.exit(0), 3000);
process.stdin.setEncoding('utf8');
process.stdin.on('data', chunk => input += chunk);
process.stdin.on('end', () => {
  clearTimeout(stdinTimeout);
  try {
    const data = JSON.parse(input);
    const model = data.model?.display_name || 'Claude';
    const dir = data.workspace?.current_dir || process.cwd();
    const session = data.session_id || '';
    const remaining = data.context_window?.remaining_percentage;

    // Context usage, normalized so 100% = the auto-compact trigger point.
    // Claude Code reserves ~16.5% of the window as auto-compact buffer.
    const AUTO_COMPACT_BUFFER_PCT = 16.5;
    let ctx = '';
    if (remaining != null) {
      const usableRemaining = Math.max(0, ((remaining - AUTO_COMPACT_BUFFER_PCT) / (100 - AUTO_COMPACT_BUFFER_PCT)) * 100);
      const used = Math.max(0, Math.min(100, Math.round(100 - usableRemaining)));

      const filled = Math.floor(used / 10);
      const bar = '█'.repeat(filled) + '░'.repeat(10 - filled);

      if (used < 50) {
        ctx = ` \x1b[32m${bar} ${used}%\x1b[0m`;
      } else if (used < 65) {
        ctx = ` \x1b[33m${bar} ${used}%\x1b[0m`;
      } else if (used < 80) {
        ctx = ` \x1b[38;5;208m${bar} ${used}%\x1b[0m`;
      } else {
        ctx = ` \x1b[5;31m💀 ${bar} ${used}%\x1b[0m`;
      }
    }

    // Current in-progress task from this session's todo files.
    let task = '';
    const claudeDir = process.env.CLAUDE_CONFIG_DIR || path.join(os.homedir(), '.claude');
    const todosDir = path.join(claudeDir, 'todos');
    if (session && fs.existsSync(todosDir)) {
      try {
        const files = fs.readdirSync(todosDir)
          .filter(f => f.startsWith(session) && f.includes('-agent-') && f.endsWith('.json'))
          .map(f => ({ name: f, mtime: fs.statSync(path.join(todosDir, f)).mtime }))
          .sort((a, b) => b.mtime - a.mtime);

        if (files.length > 0) {
          try {
            const todos = JSON.parse(fs.readFileSync(path.join(todosDir, files[0].name), 'utf8'));
            const inProgress = todos.find(t => t.status === 'in_progress');
            if (inProgress) task = inProgress.activeForm || '';
          } catch (e) {}
        }
      } catch (e) {
        // Never break the statusline on filesystem errors.
      }
    }

    // Git branch and working-tree changes (ccstatusline-style), silent outside repos.
    let gitInfo = '';
    try {
      let branch = git(['rev-parse', '--abbrev-ref', 'HEAD'], dir);
      if (branch === 'HEAD') branch = git(['rev-parse', '--short', 'HEAD'], dir); // detached
      let changes = '';
      try {
        const stat = git(['diff', '--shortstat', 'HEAD'], dir);
        const ins = /(\d+) insertion/.exec(stat);
        const del = /(\d+) deletion/.exec(stat);
        changes = ` \x1b[33m(+${ins ? ins[1] : 0},-${del ? del[1] : 0})\x1b[0m`;
      } catch (e) {
        // Repo without commits yet, or diff failed -- skip the counter.
      }
      gitInfo = ` │ \x1b[35m⎇ ${branch}\x1b[0m${changes}`;
    } catch (e) {
      // Not a git repo, or git missing -- omit the segment.
    }

    const dirname = path.basename(dir);
    if (task) {
      process.stdout.write(`\x1b[2m${model}\x1b[0m │ \x1b[1m${task}\x1b[0m │ \x1b[2m${dirname}\x1b[0m${gitInfo}${ctx}`);
    } else {
      process.stdout.write(`\x1b[2m${model}\x1b[0m │ \x1b[2m${dirname}\x1b[0m${gitInfo}${ctx}`);
    }
  } catch (e) {
    // Silent fail on parse errors.
  }
});
