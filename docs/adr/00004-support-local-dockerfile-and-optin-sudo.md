# ADR 00004: Support local Dockerfile and opt-in sudo

- Status: accepted
- Date: 2026-07-04
- Supersedes: none
- Superseded by: none

## Context

この workspace では、ホスト固有の追加ツールやパッケージを入れたい一方で、リポジトリ管理下の `Dockerfile` へ各利用者の事情を直接混ぜたくない。

また、通常は非 root 運用を保ちたいが、開発用途では `copilot` ユーザーから一時的に root 権限のコマンドを使いたい場合もある。

## Decision

ローカル専用の `Dockerfile.local` を ignore 対象で許容し、`copilot` ユーザーへの passwordless sudo は build 引数で opt-in にする。

- `WORKSPACE_DOCKERFILE=Dockerfile.local` でローカル Dockerfile を選べるようにする
- ローカル Dockerfile 利用時は、既定の `Dockerfile` から base image を先に build して、それを土台に拡張する
- `ENABLE_PASSWORDLESS_SUDO=1` のときだけ `copilot` ユーザーへ passwordless sudo を付与する

## Consequences

個人用の追加ツールは `Dockerfile.local` に閉じ込められるため、共有設定を汚さずに拡張しやすくなる。

一方で、passwordless sudo は誤操作や権限昇格のハードルを下げる。既定では無効にして、必要な利用者だけが明示的に有効化する前提を維持する。
