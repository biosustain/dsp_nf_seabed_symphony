# =============================================================================
# SeqKit — FASTA/FASTQ statistics and manipulation
#
# One tool, one image. Pinned to match
#   modules/nf-core/seqkit/stats/environment.yml
#
# Build:
#   docker build -t seabed-seqkit:2.13.0 docker/seqkit/
# =============================================================================

FROM mambaorg/micromamba:1.5.8

ARG TOOL_VERSION=2.13.0

LABEL org.opencontainers.image.title="seabed-seqkit"
LABEL org.opencontainers.image.description="SeqKit — cross-platform toolkit for FASTA/FASTQ files"
LABEL org.opencontainers.image.version="${TOOL_VERSION}"
LABEL org.opencontainers.image.source="https://github.com/biosustain/dsp_nf_seabed_symphony"

# procps supplies `ps`, which Nextflow uses to collect per-task resource metrics
USER root
RUN apt-get update \
    && apt-get install -y --no-install-recommends procps \
    && rm -rf /var/lib/apt/lists/*
USER $MAMBA_USER

RUN micromamba install -y -n base -c conda-forge -c bioconda \
        seqkit=${TOOL_VERSION} \
    && micromamba clean --all --yes

# Activate the base env for subsequent RUN steps and at container runtime
ARG MAMBA_DOCKERFILE_ACTIVATE=1

# Fail the build rather than ship a broken image
RUN seqkit version

WORKDIR /data
