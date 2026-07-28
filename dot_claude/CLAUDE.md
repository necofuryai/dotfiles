
## Test Failure Policy
When you encounter ANY test failure or warning during execution — whether caused by your changes or pre-existing — fix it immediately. Never skip, ignore, or defer test failures with "pre-existing" or "unrelated to this change" as justification. The full test suite must be green before marking work complete. The application must be shippable to customers at all times.

## Memory Verification Policy
メモリ (auto memory) の記述はスナップショットであり、リポジトリの現物が常に正。メモリのファイル名・設定値・手順を根拠に判断する前に、必ず該当ファイルを Read/Grep で再確認し、食い違いがあればメモリ側を更新する。
