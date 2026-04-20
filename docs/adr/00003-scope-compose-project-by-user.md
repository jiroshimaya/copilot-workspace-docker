# ADR 00003: Scope compose project names by user

- Status: accepted
- Date: 2026-04-20
- Supersedes: none
- Superseded by: none

## Context

この workspace は、bind mount を避けて Docker volume に状態を閉じ込める前提で設計している。

しかし rootful Docker では、同じホスト上の利用者が同一 daemon を共有する。compose project 名がユーザー非依存のままだと、同じリポジトリ名から起動した別ユーザー同士で volume 名が衝突し、意図せず同じ workspace 状態を共有してしまう。

これは認証情報や開発中ファイルの混線につながりやすく、事故的な状態破壊や情報混入のリスクがある。

## Decision

compose project 名の既定値にホスト側の `USER` を含める。

- `scripts/compose.sh` は `COMPOSE_PROJECT_NAME` 未指定時に `USER` を正規化して `copilot-workspace-$USER` 形式の project 名を設定する
- 明示的な `COMPOSE_PROJECT_NAME` 指定は引き続き優先する

## Consequences

同じホスト daemon を共有する環境でも、ユーザーごとに volume 名が分離され、workspace の accidental な共有を起こしにくくなる。

一方で、既存の非ユーザー分離 project 名で作成済みの volume は、そのままでは新しい既定 project から参照されない。既存状態を引き継ぎたい場合は、従来の project 名を `COMPOSE_PROJECT_NAME` で明示するか、必要なデータを移行する必要がある。
