# =============================================================================
# Whokaryote — prokaryote / eukaryote contig classification
#
# One function, one image. Pinned to match
#   modules/local/whokaryote/environment.yml
#
# Whokaryote orchestrates two other executables rather than reimplementing them,
# so both are installed here as runtime dependencies of this one function:
#   - Tiara    (deep-learning classifier)  — note: conda-forge, NOT bioconda
#   - Prodigal (gene prediction)
#
# This image is large (~3 GB): Tiara pulls in PyTorch.
#
# Build:
#   docker build -t seabed-whokaryote:1.1.2 docker/whokaryote/
# =============================================================================

FROM mambaorg/micromamba:1.5.8

ARG TOOL_VERSION=1.1.2
ARG TIARA_VERSION=1.0.3
ARG PRODIGAL_VERSION=2.6.3

LABEL org.opencontainers.image.title="seabed-whokaryote"
LABEL org.opencontainers.image.description="Whokaryote — classify metagenomic contigs as prokaryotic or eukaryotic"
LABEL org.opencontainers.image.version="${TOOL_VERSION}"
LABEL org.opencontainers.image.source="https://github.com/biosustain/dsp_nf_seabed_symphony"

# procps supplies `ps`, which Nextflow uses to collect per-task resource metrics
USER root
RUN apt-get update \
    && apt-get install -y --no-install-recommends procps \
    && rm -rf /var/lib/apt/lists/*
USER $MAMBA_USER

RUN micromamba install -y -n base \
        -c conda-forge \
        -c bioconda \
        whokaryote=${TOOL_VERSION} \
        tiara=${TIARA_VERSION} \
        prodigal=${PRODIGAL_VERSION} \
    && micromamba clean --all --yes

# Put the env on PATH directly so the tool resolves even when the container is
# run with its entrypoint overridden (which some Nextflow configurations do).
ENV PATH="/opt/conda/bin:${PATH}"

ARG MAMBA_DOCKERFILE_ACTIVATE=1

# whokaryote.py has no --version flag, so --help is the smoke test
RUN whokaryote.py --help > /dev/null \
    && tiara --help > /dev/null \
    && prodigal -v

WORKDIR /data
