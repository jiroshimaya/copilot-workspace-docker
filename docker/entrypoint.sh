#!/usr/bin/env bash
set -euo pipefail

mkdir -p "${HOME}/.config/gh" "${HOME}/.copilot" /workspace

exec "$@"
