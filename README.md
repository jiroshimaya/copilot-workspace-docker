# copilot-workspace-docker

GitHub Copilot CLI をホストへ直接入れずに試すための、Docker ベースの作業用 workspace です。

このリポジトリは、Copilot CLI / `gh` / `git` / `uv` を含むコンテナを立ち上げ、ホスト側とは bind mount せずに Docker volume へ状態を閉じ込めることを目的にしています。`fictional-scientists` 側で使っていた開発向け設定もなるべく揃え、`$HOME/development` を標準作業ディレクトリにしつつ、`bash`・`tmux`・ビルド系ツールを同梱しています。

## 含まれるもの

- `Dockerfile`: 再現可能な実行環境
- `compose.yaml`: 日常利用の入口
- `scripts/copilot-compose.sh`: ホストの `gh` 認証を引き継いで `docker compose` を呼ぶヘルパー
- `docker/entrypoint.sh`: 起動時の最小セットアップ
- `scripts/systemd/copilot-workspace-docker.service.example`: 常駐用の user service サンプル

## 前提

ホスト側では以下を使える状態にしてください。

- Docker Engine
- Docker Compose Plugin
- ホストで`gh auth login` 済み

## ビルドと起動

```bash
# イメージ作成
./scripts/copilot-compose.sh build

# 常駐ワークスペースとして起動
./scripts/copilot-compose.sh up

# シェルに入る
./scripts/copilot-compose.sh exec

# 1 回だけ Copilot CLI を使う
./scripts/copilot-compose.sh run --rm workspace copilot

# 片付ける
./scripts/copilot-compose.sh down
```

BuildKit 環境によっては build 時だけ DNS 解決に失敗することがあるため、この `compose.yaml` では `build.network: host` を指定しています。これは build 中のネットワーク経路だけをホスト側へ寄せる回避策です。

## コンテナ内での作業例

`/home/copilot/development` は Docker volume です。ホストのリポジトリや設定ディレクトリは既定では bind mount しません。必要なものだけコンテナ内で取得してください。

```bash
./scripts/copilot-compose.sh exec

cd ~/development
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
- `bash`
- `tmux`
- `build-essential`

`copilot-cli` は npm パッケージ `@github/copilot` からインストールします。バージョンを固定したい場合は build 時に `COPILOT_CLI_VERSION` を渡してください。

対話シェルでは、ホストの `~/.bashrc` に合わせて `BASH_ENV="$HOME/.bashexports"` を設定し、次の alias も入れています。

```bash
export BASH_ENV="$HOME/.bashexports"
[ -f "$BASH_ENV" ] && . "$BASH_ENV"
alias copilot='copilot --yolo --bash-env=on'
```

```bash
COPILOT_CLI_VERSION=latest ./scripts/copilot-compose.sh build
```

## 認証情報とセキュリティ方針

- コンテナは root ではなく `copilot` ユーザーで動かします
- 永続化対象は Docker 管理の `copilot-workspace`, `copilot-gh-config`, `copilot-cli-config` volume に限定します
- ホストのリポジトリ、`~/.config/gh`、`~/.copilot`、`~/.gitconfig`、`~/.ssh` は既定ではコンテナへ持ち込みません
- ホスト側で `gh auth login` 済みなら、helper script が token だけを取り出して起動時にコンテナ側 `gh` へ再ログインさせます
- ホスト側へ影響する経路は、明示的に渡した環境変数とネットワーク通信に絞られます
- 状態を完全に消したいときは `docker compose down -v` を実行してください

ホストとコンテナの間でファイルを受け渡したいときは、bind mount ではなく `docker compose cp` を使う想定です。

```bash
# ホスト -> コンテナ
./scripts/copilot-compose.sh cp ./local-script.py workspace:/home/copilot/development/local-script.py

# コンテナ -> ホスト
./scripts/copilot-compose.sh cp workspace:/home/copilot/development/output.json ./output.json
```

