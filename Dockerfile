FROM python:3.12-slim-bookworm

ARG USERNAME=copilot
ARG USER_UID=1000
ARG USER_GID=1000
ARG COPILOT_CLI_VERSION=latest
ARG ZELLIJ_VERSION=0.44.1

ENV DEBIAN_FRONTEND=noninteractive \
    PATH="/home/${USERNAME}/.local/bin:${PATH}" \
    SHELL="/bin/bash" \
    UV_LINK_MODE=copy \
    DEVELOPMENT_DIR="/home/${USERNAME}/development" \
    TERM="xterm-256color"

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        bash \
        build-essential \
        ca-certificates \
        curl \
        git \
        gnupg \
        jq \
        less \
        libreoffice \
        fonts-noto-cjk \
        micro \
        nano \
        openssh-client \
        procps \
        tmux \
        zsh \
    && rm -rf /var/lib/apt/lists/*

RUN case "$(dpkg --print-architecture)" in \
        amd64) zellij_arch='x86_64-unknown-linux-musl' ;; \
        arm64) zellij_arch='aarch64-unknown-linux-musl' ;; \
        *) echo "unsupported architecture: $(dpkg --print-architecture)" >&2; exit 1 ;; \
    esac \
    && zellij_asset="zellij-${zellij_arch}.tar.gz" \
    && zellij_sha_asset="zellij-${zellij_arch}.sha256sum" \
    && curl -fsSLo "/tmp/${zellij_asset}" \
        "https://github.com/zellij-org/zellij/releases/download/v${ZELLIJ_VERSION}/${zellij_asset}" \
    && curl -fsSLo "/tmp/${zellij_sha_asset}" \
        "https://github.com/zellij-org/zellij/releases/download/v${ZELLIJ_VERSION}/${zellij_sha_asset}" \
    && cd /tmp \
    && tar -xzf "${zellij_asset}" \
    && expected_zellij_sha="$(awk '{print $1}' "${zellij_sha_asset}")" \
    && echo "${expected_zellij_sha}  zellij" | sha256sum -c - \
    && install -m 0755 zellij /usr/local/bin/zellij \
    && rm -f "/tmp/${zellij_asset}" "/tmp/${zellij_sha_asset}" /tmp/zellij

RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get update \
    && apt-get install -y --no-install-recommends gh nodejs \
    && npm install -g "@github/copilot@${COPILOT_CLI_VERSION}" \
    && npm cache clean --force \
    && rm -rf /var/lib/apt/lists/*

RUN pip install --no-cache-dir uv

RUN groupadd --gid "${USER_GID}" "${USERNAME}" \
    && useradd \
        --uid "${USER_UID}" \
        --gid "${USER_GID}" \
        --create-home \
        --shell /bin/bash \
        "${USERNAME}"

RUN mkdir -p "${DEVELOPMENT_DIR}" "${DEVELOPMENT_DIR}"/worktrees /home/"${USERNAME}"/.config/gh /home/"${USERNAME}"/.copilot \
    && touch /home/"${USERNAME}"/.bashrc \
    && printf "%s\n" \
        "export BASH_ENV=\"\$HOME/.bashexports\"" \
        "[ -f \"\$BASH_ENV\" ] && . \"\$BASH_ENV\"" \
        "alias copilot='copilot --allow-all-tools --allow-all-paths --bash-env=on'" \
        >> /home/"${USERNAME}"/.bashrc \
    && chown -R "${USER_UID}:${USER_GID}" "${DEVELOPMENT_DIR}" /home/"${USERNAME}"

COPY docker/copilot-instructions.md /usr/local/share/copilot-workspace/copilot-instructions.md
COPY docker/entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

WORKDIR ${DEVELOPMENT_DIR}
USER ${USERNAME}
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["bash"]
