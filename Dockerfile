# Dockerfile (non-root replacement)
FROM ubuntu:22.04

LABEL description="Ubuntu-based container with tree (non-root user)" \
      version="1.0.0" \
      maintainer="christina@lifebit.ai" \
      name="quay.io/lifebitaiorg/ubuntu-tree"

ARG DEBIAN_FRONTEND=noninteractive
# Overridable at build time to match host/CI UID/GID (prevents permission headaches on bind mounts)
ARG SPAMMER_USER=spammer
ARG SPAMMER_UID=1000
ARG SPAMMER_GID=1000

# Install the same tools you had
RUN apt-get update -y \
  && apt-get install -y --no-install-recommends procps tree ca-certificates bash coreutils \
  && rm -rf /var/lib/apt/lists/*

# Create non-root user and writable dirs
RUN groupadd -g "${SPAMMER_GID}" "${SPAMMER_USER}" \
  && useradd -m -u "${SPAMMER_UID}" -g "${SPAMMER_GID}" -s /bin/bash "${SPAMMER_USER}" \
  && mkdir -p /work /opt/spammer \
  && chown -R "${SPAMMER_UID}:${SPAMMER_GID}" /work /opt/spammer /tmp

ENV HOME=/home/${SPAMMER_USER} \
    TMPDIR=/tmp \
    PATH=/opt/spammer/bin:$PATH
WORKDIR /work

# Drop privileges permanently
USER ${SPAMMER_USER}

ENTRYPOINT ["/bin/bash"]
CMD ["-lc", "echo 'non-root image ready'; exec bash"]
