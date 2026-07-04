# ADR 00004: Expose workspace dev ports

- Status: accepted
- Date: 2026-07-04
- Supersedes: none
- Superseded by: none

## Context

この workspace は通常、コンテナ内で開発サーバーや API サーバーを立ち上げて作業する。

しかし既定の compose 設定では、コンテナ内で listen しているポートがホストへ publish されない。そのため、同一 LAN 上の別端末ブラウザから Vite dev server や FastAPI を直接確認したいケースで、毎回 ad-hoc に `docker run -p` 相当の起動条件を考える必要があった。

## Decision

workspace サービスは、フロントエンドとバックエンドの開発用ポートを既定でホストへ publish する。

- `4173:4173` を既定で publish する
- `8001:8001` を既定で publish する
- 必要に応じて `COPILOT_WORKSPACE_FRONTEND_PORT` / `COPILOT_WORKSPACE_BACKEND_PORT` でホスト側ポート番号を上書きできる

## Consequences

コンテナ内で `0.0.0.0` に bind する dev server は、ホスト経由で LAN 上の別端末から確認しやすくなる。

一方で、該当ポートはホスト側で利用中だと compose 起動に失敗する。その場合は環境変数で別ポートへ退避するか、競合プロセスを停止する必要がある。
