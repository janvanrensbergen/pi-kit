FROM docker/sandbox-templates:shell
ARG PI_VERSION=0.84.3

LABEL org.opencontainers.image.title="Docker Sandbox Template for Pi Coding Agent"
LABEL org.opencontainers.image.description="Sandboxed environment for running Pi coding agent"
LABEL org.opencontainers.image.version="${PI_VERSION}"
LABEL org.opencontainers.image.licenses="MIT"
LABEL com.docker.sandboxes="templates"
LABEL com.docker.sandboxes.base="docker/sandbox-templates:shell"
LABEL com.docker.sandboxes.flavor="pi"

# Install fd-find so pi doesn't download fd at first boot. Debian's
# package ships the binary as `fdfind`; pi looks for `fd`, so symlink it.
USER root
RUN apt-get update \
    && apt-get install -y --no-install-recommends fd-find \
    && ln -sf /usr/bin/fdfind /usr/bin/fd \
    && rm -rf /var/lib/apt/lists/*

# Install Pi coding agent globally as the agent user.
# The binary is published under the @earendil-works scope (matches the
# globally installed package and all pi docs/skill references).
USER agent
RUN npm install -g @earendil-works/pi-coding-agent@${PI_VERSION}

# Bake this repository as an installed pi package. `.dockerignore` keeps the
# kit source (skills/, themes/, prompts/, extensions/, package.json,
# settings.json) and excludes .git/node_modules/.pi. The image is baked fully
# configured and offline: settings.json is written to the run user's global
# config, `/opt/pi-kit` is registered as a local-path pi package, and the five
# selection packages are pre-installed (floating to latest) so first boot does
# no auto-install and no network fetch.
COPY . /opt/pi-kit
RUN mkdir -p ~/.pi/agent \
    && cp /opt/pi-kit/settings.json ~/.pi/agent/settings.json \
    && pi install /opt/pi-kit \
    && pi install npm:pi-subagents \
    && pi install npm:@narumitw/pi-plan-mode \
    && pi install npm:pi-hermes-memory \
    && pi install npm:pi-mcp-adapter \
    && pi install npm:pi-web-access \
    && npm cache clean --force

# No ENTRYPOINT: spec.yaml owns [pi, --approve]; the image stays binding-neutral.