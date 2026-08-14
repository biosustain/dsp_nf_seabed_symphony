# =============================================================================
# Filtlong — quality filtering for long reads
#
# One tool, one image. Pinned to match
#   modules/nf-core/filtlong/environment.yml
#
# Build:
#   docker build -t seabed-filtlong:0.2.1 docker/filtlong/
# =============================================================================

FROM mambaorg/micromamba:1.5.8

ARG TOOL_VERSION=0.2.1

LABEL org.opencontainers.image.title="seabed-filtlong"
LABEL org.opencontainers.image.description="Filtlong — quality filtering tool for long sequencing reads"
LABEL org.opencontainers.image.version="${TOOL_VERSION}"
LABEL org.opencontainers.image.source="https://github.com/biosustain/dsp_nf_seabed_symphony"

# procps supplies `ps`, which Nextflow uses to collect per-task resource metrics
USER root
RUN apt-get update \
    && apt-get install -y --no-install-recommends procps \
    && rm -rf /var/lib/apt/lists/*
USER $MAMBA_USER

RUN micromamba install -y -n base -c conda-forge -c bioconda \
        filtlong=${TOOL_VERSION} \
    && micromamba clean --all --yes

# Put the env on PATH directly so the tool resolves even when the container is
# run with its entrypoint overridden (which some Nextflow configurations do).
ENV PATH="/opt/conda/bin:${PATH}"

ARG MAMBA_DOCKERFILE_ACTIVATE=1

# Fail the build rather than ship a broken image
RUN filtlong --version

WORKDIR /data
