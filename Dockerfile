FROM python:3.12-slim-bookworm

ARG USERNAME=copilot
ARG USER_UID=1000
ARG USER_GID=1000
ARG COPILOT_CLI_VERSION=latest

ENV DEBIAN_FRONTEND=noninteractive \
    PATH="/home/${USERNAME}/.local/bin:${PATH}" \
    UV_LINK_MODE=copy

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        bash \
        ca-certificates \
        curl \
        git \
        gnupg \
        jq \
        less \
        openssh-client \
        procps \
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
        --shell /bin/zsh \
        "${USERNAME}"

RUN mkdir -p /workspace /home/"${USERNAME}"/.config/gh /home/"${USERNAME}"/.copilot \
    && chown -R "${USER_UID}:${USER_GID}" /workspace /home/"${USERNAME}"

COPY docker/entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

WORKDIR /workspace
USER ${USERNAME}
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["bash"]
