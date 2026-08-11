# =============================================================================
# NanoPlot — Nanopore read length / quality visualisation
#
# One tool, one image. Pinned to match
#   modules/nf-core/nanoplot/environment.yml
#
# Build:
#   docker build -t seabed-nanoplot:1.47.0 docker/nanoplot/
# =============================================================================

FROM mambaorg/micromamba:1.5.8

ARG TOOL_VERSION=1.47.0

LABEL org.opencontainers.image.title="seabed-nanoplot"
LABEL org.opencontainers.image.description="NanoPlot — plotting suite for Oxford Nanopore sequencing data"
LABEL org.opencontainers.image.version="${TOOL_VERSION}"
LABEL org.opencontainers.image.source="https://github.com/biosustain/dsp_nf_seabed_symphony"

# procps supplies `ps`, which Nextflow uses to collect per-task resource metrics
USER root
RUN apt-get update \
    && apt-get install -y --no-install-recommends procps \
    && rm -rf /var/lib/apt/lists/*
USER $MAMBA_USER

RUN micromamba install -y -n base -c conda-forge -c bioconda \
        nanoplot=${TOOL_VERSION} \
    && micromamba clean --all --yes

# Activate the base env for subsequent RUN steps and at container runtime
ARG MAMBA_DOCKERFILE_ACTIVATE=1

# Fail the build rather than ship a broken image
RUN NanoPlot --version

WORKDIR /data
