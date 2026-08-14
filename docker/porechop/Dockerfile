# =============================================================================
# Porechop — Oxford Nanopore adapter trimming
#
# One tool, one image. Pinned to match
#   modules/nf-core/porechop/porechop/environment.yml
#
# pigz is included because the nf-core module's environment declares it:
# Porechop shells out to it for parallel gzip compression of its output. It is
# a runtime dependency of this one tool, not a second analysis tool.
#
# Build:
#   docker build -t seabed-porechop:0.2.4 docker/porechop/
# =============================================================================

FROM mambaorg/micromamba:1.5.8

ARG TOOL_VERSION=0.2.4
ARG PIGZ_VERSION=2.8

LABEL org.opencontainers.image.title="seabed-porechop"
LABEL org.opencontainers.image.description="Porechop — adapter trimmer for Oxford Nanopore reads"
LABEL org.opencontainers.image.version="${TOOL_VERSION}"
LABEL org.opencontainers.image.source="https://github.com/biosustain/dsp_nf_seabed_symphony"

# procps supplies `ps`, which Nextflow uses to collect per-task resource metrics
USER root
RUN apt-get update \
    && apt-get install -y --no-install-recommends procps \
    && rm -rf /var/lib/apt/lists/*
USER $MAMBA_USER

RUN micromamba install -y -n base -c conda-forge -c bioconda \
        porechop=${TOOL_VERSION} \
        pigz=${PIGZ_VERSION} \
    && micromamba clean --all --yes

# Put the env on PATH directly so the tool resolves even when the container is
# run with its entrypoint overridden (which some Nextflow configurations do).
ENV PATH="/opt/conda/bin:${PATH}"

ARG MAMBA_DOCKERFILE_ACTIVATE=1

# Fail the build rather than ship a broken image
RUN porechop --version && pigz --version

WORKDIR /data
