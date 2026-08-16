# Reproducibility has two independent pins: the upstream source commit below
# and the Node image digest. Override the commit only with another reviewed,
# full 40-character SHA.
ARG SHOWDOWN_COMMIT=d43fb79a049f624c079c387d043ef53f62aed226

FROM node:24-bookworm-slim@sha256:3638d9a6fe4030bd716be989438248074489337ba3275657f93595428be4fc03 AS base

# Every stage uses the same absolute path so artifacts can move between stages
# without path translation.
WORKDIR /opt/pokemon-showdown

FROM base AS build

# Git retrieves the pinned source, and CA certificates verify GitHub's HTTPS
# connection. Package metadata is removed in the same layer to keep it small.
RUN apt-get update \
    && apt-get install --yes --no-install-recommends git ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Arguments declared before FROM must be redeclared inside a stage before RUN
# instructions can read them.
ARG SHOWDOWN_COMMIT

# Reject branches, tags, abbreviations, and malformed input before contacting
# GitHub. The final comparison proves Git resolved the requested revision.
RUN if ! printf '%s\n' "${SHOWDOWN_COMMIT}" | grep -Eq '^[0-9a-f]{40}$'; then \
        echo "SHOWDOWN_COMMIT must be a full 40-character commit SHA" >&2; \
        exit 1; \
    fi \
    && git init \
    && git remote add origin https://github.com/smogon/pokemon-showdown.git \
    && git fetch --depth=1 origin "${SHOWDOWN_COMMIT}" \
    && git checkout --detach FETCH_HEAD \
    && test "$(git rev-parse HEAD)" = "${SHOWDOWN_COMMIT}"

# npm ci follows Showdown's lockfile. Development dependencies remain available
# for compilation, then npm prune removes them from the runtime tree. Optional
# dependencies are omitted because this service does not enable their features.
RUN npm ci --omit=optional \
    && npm run build \
    && npm prune --omit=dev --omit=optional \
    && rm -rf .git

FROM base AS runtime

# Redeclaration makes the reviewed revision available to the image label.
ARG SHOWDOWN_COMMIT

ENV NODE_ENV=production

# Expose the source revision without retaining the upstream Git checkout.
LABEL io.github.kvugs.pokebattlebench.showdown-revision="${SHOWDOWN_COMMIT}"

# Copy the built upstream tree first, then replace its runtime configuration
# with the project-owned file. Both copies belong to the unprivileged user.
COPY --from=build --chown=node:node /opt/pokemon-showdown ./
COPY --chown=node:node config.js config/config.js

USER node

# EXPOSE documents the container port. Compose controls host publication.
EXPOSE 8000

# Exec form preserves operating-system signals. --skip-build is safe because
# the build stage already compiled the pinned source.
CMD ["node", "pokemon-showdown", "start", "--skip-build", "8000"]
