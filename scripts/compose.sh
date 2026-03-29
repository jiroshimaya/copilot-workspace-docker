#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${repo_root}"

if gh auth status >/dev/null 2>&1; then
    export COPILOT_HOST_GH_TOKEN
    COPILOT_HOST_GH_TOKEN="$(gh auth token)"

    export COPILOT_HOST_GH_GIT_PROTOCOL
    COPILOT_HOST_GH_GIT_PROTOCOL="$(
        awk '/^[[:space:]]+git_protocol:/{print $2; exit}' "${HOME}/.config/gh/hosts.yml" 2>/dev/null || true
    )"

    if [[ -z "${COPILOT_HOST_GH_GIT_PROTOCOL}" ]]; then
        COPILOT_HOST_GH_GIT_PROTOCOL="https"
    fi
fi

cmd="${1:-}"
shift || true

case "${cmd}" in
    build)
        exec docker compose -f "${repo_root}/compose.yaml" build "$@"
        ;;
    up)
        exec docker compose -f "${repo_root}/compose.yaml" up -d "$@"
        ;;
    exec)
        exec docker compose -f "${repo_root}/compose.yaml" exec workspace bash "$@"
        ;;
    root)
        exec docker compose -f "${repo_root}/compose.yaml" exec --user root workspace bash "$@"
        ;;
    tmux)
        exec docker compose -f "${repo_root}/compose.yaml" exec workspace tmux new-session -A -s workspace
        ;;
    cp)
        exec docker compose -f "${repo_root}/compose.yaml" cp "$@"
        ;;
    down)
        exec docker compose -f "${repo_root}/compose.yaml" down "$@"
        ;;
    "")
        echo "使い方: $(basename "$0") {build|up|exec|root|tmux|cp|down} [追加オプション...]" >&2
        exit 1
        ;;
    *)
        exec docker compose -f "${repo_root}/compose.yaml" "${cmd}" "$@"
        ;;
esac
