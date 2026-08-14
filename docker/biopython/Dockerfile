# =============================================================================
# Biopython — runtime for the pipeline's own bin/ helper scripts
#
# One function, one image. Pinned to match
#   modules/local/extractcontigsfromwhokaryote/environment.yml
#
# bin/extractContigsFromWhokaryote.py imports only Bio.SeqIO. This is the case
# the "use upstream BioContainers" rule does not cover: the code being run is
# ours, so the image has to be ours too.
#
# Build:
#   docker build -t seabed-biopython:1.84 docker/biopython/
# =============================================================================

FROM mambaorg/micromamba:1.5.8

ARG TOOL_VERSION=1.84

LABEL org.opencontainers.image.title="seabed-biopython"
LABEL org.opencontainers.image.description="Biopython runtime for nf-seabed-symphony helper scripts"
LABEL org.opencontainers.image.version="${TOOL_VERSION}"
LABEL org.opencontainers.image.source="https://github.com/biosustain/dsp_nf_seabed_symphony"

# procps supplies `ps`, which Nextflow uses to collect per-task resource metrics
USER root
RUN apt-get update \
    && apt-get install -y --no-install-recommends procps \
    && rm -rf /var/lib/apt/lists/*
USER $MAMBA_USER

RUN micromamba install -y -n base -c conda-forge \
        biopython=${TOOL_VERSION} \
    && micromamba clean --all --yes

# Put the env on PATH directly so the tool resolves even when the container is
# run with its entrypoint overridden (which some Nextflow configurations do).
ENV PATH="/opt/conda/bin:${PATH}"

ARG MAMBA_DOCKERFILE_ACTIVATE=1

# Fail the build rather than ship a broken image
RUN python -c "import Bio; print('biopython', Bio.__version__)"

WORKDIR /data
