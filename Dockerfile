

# Dockerfile.nonroot
FROM ubuntu:22.04 AS base

ARG DEBIAN_FRONTEND=noninteractive
ENV PATH=/opt/spammer/bin:$PATH \
    HOME=/home/spammer TMPDIR=/tmp

# create a system user with fixed UID/GID that you can override at build time if needed
ARG SPAMMER_USER=spammer
ARG SPAMMER_UID=1000
ARG SPAMMER_GID=1000

RUN apt-get update && apt-get install -y --no-install-recommends \
      ca-certificates curl bash coreutils ca-certificates \
 && rm -rf /var/lib/apt/lists/*

# create group & user, create dirs, and set ownership
RUN groupadd -g ${SPAMMER_GID} ${SPAMMER_USER} \
 && useradd -m -u ${SPAMMER_UID} -g ${SPAMMER_GID} -s /bin/bash ${SPAMMER_USER} \
 && mkdir -p /opt/spammer /work /opt/spammer/bin /opt/spammer/lib \
 && chown -R ${SPAMMER_UID}:${SPAMMER_GID} /opt/spammer /work /tmp

# copy pipeline scripts/binaries. If your repo has a bin/ or scripts/ folder, adjust the source path.
# Use build-time chown to avoid runtime chown (fast & safe).
COPY --chown=${SPAMMER_UID}:${SPAMMER_GID} ./bin /opt/spammer/bin
COPY --chown=${SPAMMER_UID}:${SPAMMER_GID} ./lib /opt/spammer/lib
COPY --chown=${SPAMMER_UID}:${SPAMMER_GID} ./nextflow.config ./main.nf /work/

WORKDIR /work
ENV HOME=/home/${SPAMMER_USER}

# drop privileges: run as non-root user
USER ${SPAMMER_USER}

# declare workdir as volume for Nextflow bind mount
VOLUME ["/work"]

ENTRYPOINT ["/bin/bash"]
CMD ["-c", "echo 'spammer-nf nonroot image: ready' && /bin/bash"]

