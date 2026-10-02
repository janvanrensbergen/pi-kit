FROM docker/sandbox-templates:shell-docker
ARG OMP_VERSION=18.1.14
ARG RTK_VERSION=v0.48.0
LABEL org.opencontainers.image.title="Docker Sandbox Template for Oh My Pi"
LABEL org.opencontainers.image.description="Experimental sandbox environment for Oh My Pi coding agent"
LABEL org.opencontainers.image.version="${OMP_VERSION}"
LABEL org.opencontainers.image.licenses="MIT"
LABEL com.docker.sandboxes="templates"
LABEL com.docker.sandboxes.base="docker/sandbox-templates:shell"
LABEL com.docker.sandboxes.flavor="omp"

USER root
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       ca-certificates \
       curl \
       fd-find \
       libstdc++6 \
       socat \
       unzip \
       gzip \
    && ln -sf /usr/bin/fdfind /usr/bin/fd \
    && RTK_INSTALL_DIR=/usr/local/bin RTK_VERSION=${RTK_VERSION} \
       sh -c 'curl -fsSL https://raw.githubusercontent.com/rtk-ai/rtk/refs/heads/master/install.sh | sh' \
    && rm -rf /var/lib/apt/lists/*

ENV RTK_TELEMETRY_DISABLED=1
ENV SHELL=/bin/bash
# The copilot sbx secret is a fine-grained PAT. Copilot rejects PATs under
# OMP's default chat identity (copilot-chat); the Copilot CLI identity accepts them.
ENV COPILOT_INTEGRATION_ID=copilot-developer-cli
ENV PATH="/home/agent/.local/bin:/home/agent/.bun/bin:${PATH}"
COPY --chown=agent:agent bash/bashrc /home/agent/.bashrc
COPY --chown=agent:agent rtk/config.toml /home/agent/.config/rtk/config.toml
COPY --chown=agent:agent herdr/config.toml /home/agent/.config/herdr/config.toml
COPY --chown=agent:agent omp/gcx/config.yaml /home/agent/.config/gcx/config.yaml

USER agent
RUN curl -fsSL https://bun.sh/install | bash \
    && curl -fsSL https://herdr.dev/install.sh | sh \
    && export HUNK_INSTALL_DIR=/home/agent/.local/bin \
    && curl -fsSL https://hunk.dev/install.sh | sh \
    && curl -fsSL https://ketch.run/install | sh \
    && curl -fsSL https://raw.githubusercontent.com/grafana/gcx/main/scripts/install.sh | sh \
    && command -v gcx \
    && command -v hunk \
    && command -v ketch \
    && /home/agent/.bun/bin/bun install -g @oh-my-pi/pi-coding-agent@${OMP_VERSION} \
    && rtk init -g --agent pi \
    && omp plugin install github:RockinPaul/pi-blackhole-omp

 # Install the repository resources into OMP's native global resource locations.
 # The OMP config below also declares these locations explicitly.
 COPY --chown=agent:agent skills /home/agent/.omp/agent/skills
 COPY --chown=agent:agent themes /home/agent/.omp/agent/themes
 COPY --chown=agent:agent prompts /home/agent/.omp/agent/prompts
 COPY --chown=agent:agent extensions /home/agent/.omp/agent/extensions
 COPY --chown=agent:agent omp/config.yml /home/agent/.omp/agent/config.yml
 # Blackhole global settings: footer status bar off (compaction and memory keep running).
 COPY --chown=agent:agent omp/pi-blackhole-config.json /home/agent/.omp/agent/pi-blackhole/pi-blackhole-config.json
 # Herdr's omp integration needs ~/.omp/agent/extensions, so install it after the COPY above.
 RUN herdr integration install omp
 
 RUN /home/agent/.bun/bin/bun pm cache rm 2>/dev/null || true
 
