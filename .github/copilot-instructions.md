## 全体
- 返答、PR、イシューは日本語を使ってください
- コーディング時、main ブランチの直接編集は避けること
  - git worktree で作業用ブランチを `../worktrees` に作成して作業すること
  - 不要になった worktree ブランチはこまめに削除すること
- GitHub CLI を使用してください
- このリポジトリは Docker workspace 用なので、変更時は `docker compose config` / `docker compose build` / `docker compose run` を使って検証してください
- コンテナ内の標準作業ディレクトリは `/home/copilot/development` です
