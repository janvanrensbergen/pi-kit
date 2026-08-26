FROM docker/sandbox-templates:shell
ARG PI_VERSION=0.84.3

LABEL org.opencontainers.image.title="Docker Sandbox Template for Pi Coding Agent"
LABEL org.opencontainers.image.description="Sandboxed environment for running Pi coding agent"
LABEL org.opencontainers.image.version="${PI_VERSION}"
LABEL org.opencontainers.image.licenses="MIT"
LABEL com.docker.sandboxes="templates"
LABEL com.docker.sandboxes.base="docker/sandbox-templates:shell"
LABEL com.docker.sandboxes.flavor="pi"

# Install Pi coding agent globally as the agent user.
# The binary is published under the @earendil-works scope (matches the
# globally installed package and all pi docs/skill references).
USER agent
RUN npm install -g @earendil-works/pi-coding-agent@${PI_VERSION}

# Bake this repository as an installed pi package. `.dockerignore` keeps the
# kit source (skills/, themes/, prompts/, extensions/, package.json,
# settings.json) and excludes .git/node_modules/.pi. `pi install /opt/pi-kit`
# registers /opt/pi-kit as a local-path pi package in ~/.pi/agent/settings.json,
# so the kit's resources resolve at boot. Bundle first, then register.
COPY . /opt/pi-kit
RUN mkdir -p ~/.pi/agent \
    && pi install /opt/pi-kit \
    && npm cache clean --force

# No ENTRYPOINT: spec.yaml owns [pi, --approve]; the image stays binding-neutral.