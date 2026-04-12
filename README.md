# copilot-workspace-docker

GitHub Copilot CLI をホストへ直接入れずに試すための、Docker ベースの作業用 workspace です。

このリポジトリは、Copilot CLI / `gh` / `git` / `uv` / `zellij` / `micro` などを含むコンテナを立ち上げ、ホスト側とは bind mount せずに Docker volume へ状態を閉じ込めることを目的にしています。

## 前提

ホスト側では以下を使える状態にしてください。

- Docker Engine
- Docker Compose Plugin
- ホストで`gh auth login` 済み

## ビルドと起動

```bash
# イメージ作成
./scripts/compose.sh build

# 常駐ワークスペースとして起動
./scripts/compose.sh up

# シェルに入る
./scripts/compose.sh exec

# root シェルに入る（apt-get で追加インストールしたいとき）
./scripts/compose.sh root

# zellij セッションへ入る（あれば再開、なければ新規作成）
./scripts/compose.sh zellij

# 1 回だけ Copilot CLI を使う
./scripts/compose.sh run --rm workspace copilot

# 片付ける
./scripts/compose.sh down
```

BuildKit 環境によっては build 時だけ DNS 解決に失敗することがあるため、この `compose.yaml` では `build.network: host` を指定しています。これは build 中のネットワーク経路だけをホスト側へ寄せる回避策です。

`./scripts/compose.sh zellij` はコンテナ内で `workspace` セッションへの attach を試し、既存セッションがなければ同名の新規セッションを起動します。作業を再開したいときは `exec` よりこちらを使うと、前回の `zellij` セッションへすぐ戻れます。

## コンテナ内での作業例

`/home/copilot/development` は Docker volume です。ホストのリポジトリや設定ディレクトリは既定では bind mount しません。必要なものだけコンテナ内で取得してください。

```bash
./scripts/compose.sh zellij

cd ~/development
gh repo clone owner/repository
cd repository

# ブラウザ等でcopilotにログイン
copilot login

# copilot実行
# aliasによってツール実行とパス制限が広く許可された状態で実行されるため注意。必要に応じて権限を狭めること。
copilot
```

素のシェルだけ欲しい場合は、従来どおり `./scripts/compose.sh exec` も使えます。

コンテナ内で追加の Debian パッケージを事後インストールしたい場合は、`./scripts/compose.sh root` で root シェルへ入れます。

```bash
./scripts/compose.sh up
./scripts/compose.sh root

apt-get update
apt-get install -y tree
exit

./scripts/compose.sh exec
tree --version
```

`root` は明示的に要求したときだけ使える導線です。通常作業は引き続き `copilot` ユーザーの `exec` / `zellij` を使う前提です。また、ここで行った `apt-get` の変更はコンテナの writable layer に入るため、`docker compose down` や image rebuild の扱いによっては失われる点に注意してください。

## 含めているツール

- `copilot-cli`
- `gh`
- `git`
- `libreoffice`
- `micro`
- `nano`
- `uv`
- `bash`
- `zellij`

`copilot-cli` は npm パッケージ `@github/copilot` からインストールします。バージョンを固定したい場合は build 時に `COPILOT_CLI_VERSION` を渡してください。

対話シェルでは、ホストの `~/.bashrc` に合わせて `BASH_ENV="$HOME/.bashexports"` を設定し、次の alias も入れています。

```bash
export BASH_ENV="$HOME/.bashexports"
[ -f "$BASH_ENV" ] && . "$BASH_ENV"
alias copilot='copilot --allow-all-tools --allow-all-paths --bash-env=on'
```

```bash
COPILOT_CLI_VERSION=latest ./scripts/compose.sh build
```

## 認証情報とセキュリティ方針

- コンテナは root ではなく `copilot` ユーザーで動かします
- 永続化対象は Docker 管理の `copilot-workspace`, `copilot-gh-config`, `copilot-cli-config` volume に限定します
- ホストのリポジトリ、`~/.config/gh`、`~/.copilot`、`~/.gitconfig`、`~/.ssh` は既定ではコンテナへ持ち込みません
- ホスト側で `gh auth login` 済みなら、helper script が token だけを取り出して起動時にコンテナ側 `gh` へ再ログインさせます
- コンテナ起動時には `gh auth setup-git` も実行し、コンテナ内の Git 操作でも `gh` の認証設定を使えるようにします
- copilot-cliへのログインはコンテナ内で実行する必要があります。
- copilot-cliはaliasにより `--allow-all-tools --allow-all-paths` 付きで実行されます。URL 制限は既定の HTTPS のままですが、それでも本当にこの設定でよいかは各自の状況に合わせて慎重に判断してください。
  - ホスト側へ影響する経路は、明示的に渡した環境変数とネットワーク通信に絞られますが、リモートリポジトリの破壊や情報漏洩など悪さはやろうと思えばいくらでもできます。
- 状態を完全に消したいときは `docker compose down -v` を実行してください

ホストとコンテナの間でファイルを受け渡したいときは、bind mount ではなく `docker compose cp` を使う想定です。

```bash
# ホスト -> コンテナ
./scripts/compose.sh cp ./local-script.py workspace:/home/copilot/development/local-script.py

# コンテナ -> ホスト
./scripts/compose.sh cp workspace:/home/copilot/development/output.json ./output.json
```
