# Third-party licenses

Everything in this repository is released into the public domain under the
[Unlicense](LICENSE) — **except** the files listed here, which carry their own
license and are redistributed under its terms.

## `dot_claude/statusline-context.js` → `~/.claude/statusline-context.js`

Derived from `hooks/gsd-statusline.js` in
[gsd-build/get-shit-done](https://github.com/gsd-build/get-shit-done)
(GSD edition v1.30.0). The upstream repository is archived (last push 2026-05-31).

Local changes: removed the GSD update-check banner and the context-monitor
bridge file (both only meaningful inside a GSD-managed project), added the git
branch/changes segment, and pinned `AUTO_COMPACT_BUFFER_PCT` instead of reading
it from GSD config.

The notice below is reproduced in the file header as well, so the deployed copy
in `$HOME` carries it too.

```
MIT License

Copyright (c) 2025 Lex Christopherson

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```
