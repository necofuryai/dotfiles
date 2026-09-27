
## Test Failure Policy
When you encounter ANY test failure or warning during execution — whether caused by your changes or pre-existing — fix it immediately. Never skip, ignore, or defer test failures with "pre-existing" or "unrelated to this change" as justification. The full test suite must be green before marking work complete. The application must be shippable to customers at all times.

## Memory Verification Policy
メモリ (auto memory) の記述はスナップショットであり、リポジトリの現物が常に正。メモリのファイル名・設定値・手順を根拠に判断する前に、必ず該当ファイルを Read/Grep で再確認し、食い違いがあればメモリ側を更新する。

## Dialogue Language
画面上でユーザーに見せる文章はすべて日本語で書く。応答、ツール呼び出しの合間の途中報告（1 行でも）、完了報告、AskUserQuestion の質問と選択肢が対象。内部の思考、サブエージェントや Workflow へのプロンプト、コードは英語でよい。コミットメッセージは英語（git-workflow.md のとおり）。英語の文章を書いた直後や英語のツール結果を読んだ直後は、次の地の文が日本語かを出す前に確かめる。
