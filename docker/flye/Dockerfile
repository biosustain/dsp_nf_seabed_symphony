# =============================================================================
# Flye — long-read (meta)genome assembler
#
# One tool, one image. Pinned to match
#   modules/nf-core/flye/environment.yml
#
# Build:
#   docker build -t seabed-flye:2.9.5 docker/flye/
# =============================================================================

FROM mambaorg/micromamba:1.5.8

ARG TOOL_VERSION=2.9.5

LABEL org.opencontainers.image.title="seabed-flye"
LABEL org.opencontainers.image.description="Flye — de novo assembler for long reads, with metaFlye mode"
LABEL org.opencontainers.image.version="${TOOL_VERSION}"
LABEL org.opencontainers.image.source="https://github.com/biosustain/dsp_nf_seabed_symphony"

# procps supplies `ps`, which Nextflow uses to collect per-task resource metrics
USER root
RUN apt-get update \
    && apt-get install -y --no-install-recommends procps \
    && rm -rf /var/lib/apt/lists/*
USER $MAMBA_USER

RUN micromamba install -y -n base -c conda-forge -c bioconda \
        flye=${TOOL_VERSION} \
    && micromamba clean --all --yes

# Put the env on PATH directly so the tool resolves even when the container is
# run with its entrypoint overridden (which some Nextflow configurations do).
ENV PATH="/opt/conda/bin:${PATH}"

ARG MAMBA_DOCKERFILE_ACTIVATE=1

# Fail the build rather than ship a broken image
RUN flye --version

WORKDIR /data
