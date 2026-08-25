# pi-kit image: ships pi + the whole kit baked into the run user's global
# ~/.pi/agent config, so a sandbox boots fully configured with no first-boot
# npm/copy step.
#
# Multi-stage:
#   - bake:    assembles the global ~/.pi tree (settings + extension packages)
#              and the /opt/pi-kit package source. Does the network work.
#   - runtime: the shipped image. Only copies the finished ~/.pi tree and
#              /opt/pi-kit across — no build cruft, no rm -rf.
ARG PI_VERSION=0.84.3

# ---------- bake stage: assemble the whole kit into ~/.pi/agent ----------
FROM docker/sandbox-templates:shell-docker AS bake
ARG PI_VERSION
ENV PI_SKIP_VERSION_CHECK=1

# The runtime user on docker/sandbox-templates is `agent` (uid/gid 1000) with
# HOME=/home/agent. Resolve HOME from /etc/passwd so the bake works even if the
# base image's HOME ever changes; the COPY --from in runtime uses the literal
# /home/agent (see note there).
RUN HOME="$(getent passwd "$(id -un)" | cut -d: -f6)" \
    && test -n "$HOME" \
    && echo "baking pi-kit into HOME=$HOME for user $(id -un)"

# 1) install pi globally (base already ships node/npm/git)
RUN npm install -g --ignore-scripts @earendil-works/pi-coding-agent@${PI_VERSION}

# 2) bundle the kit source (build context is filtered by .dockerignore)
COPY . /opt/pi-kit
WORKDIR /opt/pi-kit

# 3) relay the portable settings.json FIRST, then append packages with pi
#    install (pi install only appends to settings.json; never overwrite after).
#    The /opt/pi-kit path package contributes its skills/themes/prompts/
#    extensions via package.json "pi" key; the five npm packages materialize
#    into ~/.pi/agent/npm/.
RUN HOME="$(getent passwd "$(id -un)" | cut -d: -f6)" \
    && mkdir -p "$HOME/.pi/agent" \
    && cp /opt/pi-kit/settings.json "$HOME/.pi/agent/settings.json" \
    && pi install /opt/pi-kit \
    && pi install npm:pi-subagents \
    && pi install npm:@narumitw/pi-plan-mode \
    && pi install npm:pi-hermes-memory \
    && pi install npm:pi-mcp-adapter \
    && pi install npm:pi-web-access

# ---------- runtime stage: the shipped lean image ----------
FROM docker/sandbox-templates:shell-docker AS runtime
ARG PI_VERSION=0.84.3

# 4) pi binary in the shipped image
RUN npm install -g --ignore-scripts @earendil-works/pi-coding-agent@${PI_VERSION}

# 5) copy only the baked state across stages. HOME is /home/agent in both
#    stages (verified: USER=agent, getent → /home/agent), so these literals
#    align with the bake paths. --chown keeps everything owned by agent.
COPY --from=bake --chown=1000:1000 /home/agent/.pi /home/agent/.pi
COPY --from=bake --chown=1000:1000 /opt/pi-kit  /opt/pi-kit

WORKDIR /workspace
# No ENTRYPOINT: the spec owns [pi, --approve], the image stays binding-neutral.