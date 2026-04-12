# ADR 00002: Prefer zellij over tmux for workspace sessions

- Status: accepted
- Date: 2026-04-12
- Supersedes: none
- Superseded by: none

## Context

この workspace では、作業再開しやすい対話セッションとして `tmux` を案内してきた。

しかし、Copilot CLI を `tmux` の中で使うと、出力内容をそのままコピーしづらい場面があり、会話結果やコード断片を外へ持ち出す操作の体験が悪かった。特に、Copilot CLI の出力を確認しながら必要な部分だけをコピーしたい用途では、terminal multiplexer 側の操作性が作業効率へ直接影響する。

一方で `zellij` では、同様の用途でも出力をコピーできることを確認できた。また、キーバインドや画面操作も `tmux` より直感的で、初見でも扱いやすい。

## Decision

workspace で継続利用する terminal multiplexer の推奨を `tmux` から `zellij` へ移す。

- `zellij` を workspace イメージへ含める
- セッション再開用の compose 導線として `./scripts/compose.sh zellij` を用意する
- `tmux` は互換性のため当面残すが、日常的な作業再開の導線としては `zellij` を優先する

## Consequences

Copilot CLI の出力を扱うときに、内容のコピーや参照がしやすくなり、対話結果をベースにした作業の往復が改善される。

また、`tmux` に慣れていない利用者でも、より少ない学習コストで persistent session を使い始めやすくなる。

一方で、既存利用者は `tmux` と `zellij` の 2 系統がしばらく併存するため、案内文や運用上の推奨を明確に保つ必要がある。
