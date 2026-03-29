# ADR 00001: Allow explicit root shell

- Status: accepted
- Date: 2026-03-29
- Supersedes: none
- Superseded by: none

## Context

この workspace は通常、`copilot` ユーザーで動作し、README でも非 root 運用を前提に説明している。

一方で、コンテナ起動後に `apt-get` で追加ライブラリを入れたいケースがある。そのたびに Dockerfile を編集して build し直すのは重く、短期的な検証や一時的な依存追加には不便だった。

ただし root 利用を既定経路へ混ぜると、通常作業でも安易に root を使いやすくなり、安全なデフォルトを崩してしまう。

## Decision

`scripts/compose.sh` に通常ユーザー用の `exec` とは別に、明示的な `root` サブコマンドを追加する。

- 通常の `exec` / `tmux` の挙動は変えない
- root 権限が必要なときだけ `./scripts/compose.sh root` を明示的に実行する
- README に用途と注意点を記載する

## Consequences

`apt-get` など root 権限が必要な作業を、既存の compose 導線を保ったまま実行できる。

一方で、root で行った変更は Docker image ではなく実行中コンテナの writable layer に入るため、再作成や運用手順によっては失われる。恒久的に必要な依存は引き続き Dockerfile へ反映すべきである。
