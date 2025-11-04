FROM ubuntu:22.04

LABEL description="NON-ROOT Ubuntu based container with tree" \
      version="22.04" \
      maintainer="david.pineyro@iifebit.ai" \
      name="quay.io/lifebitaiorg/ubuntu:22.04_non_root"

RUN apt-get --allow-releaseinfo-change update -y \
  && apt-get install procps tree -y \
  && rm -rf /var/lib/apt/lists/*

RUN useradd -m appuser

USER appuser
