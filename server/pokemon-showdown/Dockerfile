# Reproducibility has two independent pins: the upstream source commit below
# and the Node image digest. Override the commit only with another reviewed,
# full 40-character SHA.
ARG SHOWDOWN_COMMIT=d43fb79a049f624c079c387d043ef53f62aed226

FROM node:26-bookworm-slim@sha256:367679cf9792759492a486e4aa4b421764d71a9546a6dae8aab81a99eb797b3e AS base

# Every stage uses the same absolute path so artifacts can move between stages
# without path translation.
WORKDIR /opt/pokemon-showdown

FROM base AS build

# Git retrieves the pinned source, and CA certificates verify GitHub's HTTPS
# connection. Package metadata is removed in the same layer to keep it small.
# droast ignore=DF005 reason="these packages exist only in the discarded build stage and never reach the runtime image, and what they fetch is verified against SHOWDOWN_COMMIT, so a version change cannot alter the shipped artifact; an exact Debian pin would instead break the build whenever the archive drops the old version"
RUN apt-get update \
    && apt-get install --yes --no-install-recommends git ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Arguments declared before FROM must be redeclared inside a stage before RUN
# instructions can read them.
ARG SHOWDOWN_COMMIT

# Reject branches, tags, abbreviations, and malformed input before contacting
# GitHub. A length test plus a character-class test does the same work as a
# regular expression without a pipeline, whose exit status would otherwise
# depend on the base image's shell. The final comparison proves Git resolved
# the requested revision.
RUN if [ "${#SHOWDOWN_COMMIT}" -ne 40 ]; then \
        echo "SHOWDOWN_COMMIT must be a full 40-character commit SHA" >&2; \
        exit 1; \
    fi \
    && case "${SHOWDOWN_COMMIT}" in \
        *[!0-9a-f]*) \
            echo "SHOWDOWN_COMMIT must be lowercase hexadecimal" >&2; \
            exit 1 ;; \
    esac \
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

# The runtime executes `node`, never a package manager: the build stage already
# compiled the source, `--skip-build` skips the CLI's rebuild path, and
# config.js disables hotpatching. Removing them is the same kind of decision as
# `cap_drop: ALL` in Compose - it lowers what code execution inside this
# container would be worth, because a package manager is a general-purpose tool
# for fetching more code.
#
# This does not shrink the image. These bytes arrive in the base image layer,
# and deleting them here only masks them. What it does remove is the reachable
# copy, and with it a permanent stream of scanner findings against npm's own
# bundled dependencies that no change in this repository could ever resolve.
# `yarn` is a symlink, so the target under /opt has to go too.
RUN rm -rf /usr/local/lib/node_modules/npm /usr/local/lib/node_modules/corepack \
    /usr/local/bin/npm /usr/local/bin/npx /usr/local/bin/corepack \
    /usr/local/bin/yarn /usr/local/bin/yarnpkg /opt/yarn-*

USER node

# EXPOSE documents the container port. Compose controls host publication.
EXPOSE 8000

# The image reports its own readiness, so `docker run` and Compose agree
# without repeating the port in two files. This probe answers only "is the TCP
# listener ready?"; protocol and battle behavior belong in the live container
# test. Thirty retries at two seconds bound readiness to roughly 60 seconds.
HEALTHCHECK --interval=2s --timeout=1s --retries=30 \
    CMD ["node", "-e", "const s = require('node:net').connect(8000, '127.0.0.1'); s.once('connect', () => process.exit(0)); s.once('error', () => process.exit(1));"]

# Exec form preserves operating-system signals. --skip-build is safe because
# the build stage already compiled the pinned source.
CMD ["node", "pokemon-showdown", "start", "--skip-build", "8000"]
