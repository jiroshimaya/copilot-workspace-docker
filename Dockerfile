FROM python:3.12-slim-bookworm

ARG USERNAME=copilot
ARG USER_UID=1000
ARG USER_GID=1000
ARG COPILOT_CLI_VERSION=latest

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
        nano \
        openssh-client \
        procps \
        tmux \
        zsh \
    && rm -rf /var/lib/apt/lists/*

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
