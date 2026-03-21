# copilot-workspace-docker

GitHub Copilot CLI をホストへ直接入れずに試すための、Docker ベースの作業用 workspace です。

このリポジトリは、Copilot CLI / `gh` / `git` / `uv` を含むコンテナを立ち上げ、ホスト側とは bind mount せずに Docker volume へ状態を閉じ込めることを目的にしています。

## 含まれるもの

- `Dockerfile`: 再現可能な実行環境
- `compose.yaml`: 日常利用の入口
- `docker/entrypoint.sh`: 起動時の最小セットアップ
- `scripts/systemd/copilot-workspace-docker.service.example`: 常駐用の user service サンプル

## 前提

ホスト側では以下を使える状態にしてください。

- Docker Engine
- Docker Compose Plugin

認証は次のどちらかで行います。

- 環境変数で渡す
  - `COPILOT_GITHUB_TOKEN` または `GH_TOKEN`
  - 必要なら `OPENAI_API_KEY`
- コンテナ内で `gh auth login` や Copilot CLI のログインを行い、Docker volume に保存する

## ビルドと起動

```bash
# イメージ作成
docker compose build workspace

# 常駐ワークスペースとして起動
docker compose up -d workspace

# シェルに入る
docker compose exec workspace bash

# 1 回だけ Copilot CLI を使う
docker compose run --rm workspace copilot

# 片付ける
docker compose down
```

BuildKit 環境によっては build 時だけ DNS 解決に失敗することがあるため、この `compose.yaml` では `build.network: host` を指定しています。これは build 中のネットワーク経路だけをホスト側へ寄せる回避策です。

## コンテナ内での作業例

`/workspace` は Docker volume です。ホストのリポジトリや設定ディレクトリは既定では bind mount しません。必要なものだけコンテナ内で取得してください。

```bash
docker compose exec workspace bash

cd /workspace
gh repo clone owner/repository
cd repository

# Python プロジェクト例
uv sync --frozen --group dev
```

## 含めているツール

- `copilot-cli`
- `gh`
- `git`
- `uv`
- `bash` / `zsh`

`copilot-cli` は npm パッケージ `@github/copilot` からインストールします。バージョンを固定したい場合は build 時に `COPILOT_CLI_VERSION` を渡してください。

```bash
COPILOT_CLI_VERSION=latest docker compose build workspace
```

## 認証情報とセキュリティ方針

- コンテナは root ではなく `copilot` ユーザーで動かします
- 永続化対象は Docker 管理の `copilot-workspace`, `copilot-gh-config`, `copilot-cli-config` volume に限定します
- ホストのリポジトリ、`~/.config/gh`、`~/.copilot`、`~/.gitconfig`、`~/.ssh` は既定ではコンテナへ持ち込みません
- ホスト側へ影響する経路は、明示的に渡した環境変数とネットワーク通信に絞られます
- 状態を完全に消したいときは `docker compose down -v` を実行してください

ホストとコンテナの間でファイルを受け渡したいときは、bind mount ではなく `docker compose cp` を使う想定です。

```bash
# ホスト -> コンテナ
docker compose cp ./local-script.py workspace:/workspace/local-script.py

# コンテナ -> ホスト
docker compose cp workspace:/workspace/output.json ./output.json
```

## systemd から compose を起動する

常設の作業用コンテナが欲しい場合は、`scripts/systemd/copilot-workspace-docker.service.example` をユーザーサービスとして使えます。

```bash
mkdir -p ~/.config/systemd/user
cp scripts/systemd/copilot-workspace-docker.service.example \
  ~/.config/systemd/user/copilot-workspace-docker.service

# WorkingDirectory をこのリポジトリのパスへ修正してから
systemctl --user daemon-reload
systemctl --user enable --now copilot-workspace-docker.service
systemctl --user status copilot-workspace-docker.service
```

停止するときは以下です。

```bash
systemctl --user stop copilot-workspace-docker.service
```
