# ADR 00005: Support local compose overrides and Claude Code

- Status: accepted
- Date: 2026-07-04
- Supersedes: none
- Superseded by: none

## Context

この workspace では、利用者ごとに公開ポートや追加 CLI の要件が異なる。

一方で、`compose.yaml` にホスト固有設定を直接積み増すと、リポジトリ管理下の設定へローカル事情が混ざりやすい。また、手動で入れた CLI やそのホーム配下の状態は、コンテナ再作成で失われる。

## Decision

ホスト固有の compose 変更は ignore 対象ファイルで上書きできるようにし、Claude Code は image に同梱してホーム配下の状態を volume へ退避する。

- `.env.local` を任意のローカル設定ファイルとして読み込む
- `compose.override.yaml` を ignore 対象にし、必要なら個別 host で compose override を置けるようにする
- `@anthropic-ai/claude-code` を workspace image へ含める
- `~/.claude`、`~/.config/claude`、`~/.local/share/claude` を volume で永続化する

## Consequences

ポート公開や CLI バージョン固定をリポジトリ本体へハードコードしすぎず、各 host で安全に調整しやすくなる。

一方で、永続化 volume が増えるため、完全初期化時は `docker compose down -v` で Claude 関連の状態も消えることを理解して運用する必要がある。
