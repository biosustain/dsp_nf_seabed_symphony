# =============================================================================
# seabed-qc — Module 1: Preprocessing & Quality Control
# =============================================================================
# Tools included:
#   NanoPlot  1.46.1  — read quality and length visualisation
#   SeqKit    2.8.2   — read statistics
#   Filtlong  0.2.1   — length and quality filtering
#   Porechop  0.2.4   — Oxford Nanopore adapter removal
#
# Build:
#   docker build -t seabed-qc:1.0.0 docker/seabed-qc/
#
# Run (interactive):
#   docker run --rm -it -v $(pwd):/data seabed-qc:1.0.0 bash
# =============================================================================

FROM mambaorg/micromamba:1.5.8

LABEL org.opencontainers.image.title="seabed-qc"
LABEL org.opencontainers.image.version="1.0.0"
LABEL org.opencontainers.image.description="Module 1 — Preprocessing & Quality Control"
LABEL org.opencontainers.image.authors="nf-seabed-symphony"

# ── System dependencies ───────────────────────────────────────────────────────
# procps is needed by some pipeline reporting tools (e.g. memory tracking)
USER root
RUN apt-get update \
    && apt-get install -y --no-install-recommends procps \
    && rm -rf /var/lib/apt/lists/*

# ── Conda environment ─────────────────────────────────────────────────────────
# Switch back to the non-root micromamba user before installing packages
USER $MAMBA_USER

RUN micromamba install -y -n base \
        -c conda-forge \
        -c bioconda \
        python=3.9 \
        nanoplot=1.46.1 \
        seqkit=2.8.2 \
        filtlong=0.2.1 \
        porechop=0.2.4 \
    && micromamba clean --all --yes

# Activate the base environment automatically for every command
ARG MAMBA_DOCKERFILE_ACTIVATE=1

# ── Sanity checks ─────────────────────────────────────────────────────────────
RUN NanoPlot --version \
    && seqkit version \
    && filtlong --version \
    && porechop --version

WORKDIR /data
