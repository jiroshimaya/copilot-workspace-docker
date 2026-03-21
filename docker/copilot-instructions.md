## 全体
- 返答、PR、イシューは日本語を使ってください
- コーディング時、main ブランチの直接編集は避けてください
  - `git worktree` で作業用ブランチを `../worktrees` に作成して作業してください
  - 不要になった worktree ブランチはこまめに削除してください
- GitHub CLI を優先して使ってください
- このコンテナは Docker workspace 用です。変更時は `docker compose config` / `docker compose build` / `docker compose run` で検証してください
- コンテナ内の標準作業ディレクトリは `/home/copilot/development` です

## シェル設定
- 追加の環境変数は `$HOME/.bashexports` に集約し、`BASH_ENV` 経由で読み込みます
- 通知関連の環境変数はホストから引き継がれる前提です
