# =============================================================================
# Bandage — assembly graph visualisation
#
# One tool, one image. Pinned to match
#   modules/nf-core/bandage/image/environment.yml
#
# Two things this image deliberately fixes:
#   1. Bandage is a Qt GUI application. QT_QPA_PLATFORM=offscreen is set so it
#      renders without a display, which any HPC node or CI runner requires.
#   2. The nf-core module decompresses the GFA with GNU `zcat`. That is present
#      here (Debian base), unlike macOS, whose BSD `zcat` refuses .gz files.
#
# Build:
#   docker build -t seabed-bandage:0.9.0 docker/bandage/
# =============================================================================

FROM mambaorg/micromamba:1.5.8

ARG TOOL_VERSION=0.9.0

LABEL org.opencontainers.image.title="seabed-bandage"
LABEL org.opencontainers.image.description="Bandage — Bioinformatics Application for Navigating De novo Assembly Graphs Easily"
LABEL org.opencontainers.image.version="${TOOL_VERSION}"
LABEL org.opencontainers.image.source="https://github.com/biosustain/dsp_nf_seabed_symphony"

# procps for Nextflow metrics; the rest are Qt runtime libraries Bandage needs
# even in offscreen mode.
USER root
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        procps \
        libgl1 \
        libglib2.0-0 \
        libfontconfig1 \
        libdbus-1-3 \
        libxkbcommon0 \
    && rm -rf /var/lib/apt/lists/*
USER $MAMBA_USER

RUN micromamba install -y -n base -c conda-forge -c bioconda \
        bandage=${TOOL_VERSION} \
    && micromamba clean --all --yes

# Put the env on PATH directly so the tool resolves even when the container is
# run with its entrypoint overridden (which some Nextflow configurations do).
ENV PATH="/opt/conda/bin:${PATH}"

# Render without a display
ENV QT_QPA_PLATFORM=offscreen

ARG MAMBA_DOCKERFILE_ACTIVATE=1

# Fail the build rather than ship a broken image
RUN Bandage --version

WORKDIR /data
