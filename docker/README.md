# Container images

One function, one tool, one image — the nf-core convention.

### Workflow 1 — Preprocessing & QC

| Directory | Image | Tool | Version | Used by |
|---|---|---|---|---|
| [`nanoplot/`](nanoplot/Dockerfile) | `seabed-nanoplot:1.47.0` | NanoPlot | 1.47.0 | `NANOPLOT`, `NANOPLOT_TRIMMED` |
| [`seqkit/`](seqkit/Dockerfile) | `seabed-seqkit:2.13.0` | SeqKit | 2.13.0 | `SEQKIT_STATS`, `SEQKIT_STATS_TRIMMED` |
| [`filtlong/`](filtlong/Dockerfile) | `seabed-filtlong:0.2.1` | Filtlong | 0.2.1 | `FILTLONG_MINLEN`, `FILTLONG_QUALITY` |
| [`porechop/`](porechop/Dockerfile) | `seabed-porechop:0.2.4` | Porechop | 0.2.4 | `PORECHOP_PORECHOP` |

### Workflow 2 — Assembly & Annotation

| Directory | Image | Tool | Version | Used by |
|---|---|---|---|---|
| [`flye/`](flye/Dockerfile) | `seabed-flye:2.9.5` | Flye | 2.9.5 | `FLYE` |
| [`bandage/`](bandage/Dockerfile) | `seabed-bandage:0.9.0` | Bandage | 0.9.0 | `BANDAGE_IMAGE` |
| [`whokaryote/`](whokaryote/Dockerfile) | `seabed-whokaryote:1.1.2` | Whokaryote | 1.1.2 | `WHOKARYOTE` |
| [`biopython/`](biopython/Dockerfile) | `seabed-biopython:1.84` | Biopython | 1.84 | `EXTRACT_PROKARYOTE`, `EXTRACT_EUKARYOTE` |

Each image installs exactly one analysis tool, pinned to the same version as the
corresponding module's `environment.yml`. If you bump a module, bump its
Dockerfile to match.

Two images carry extra executables. These are runtime dependencies of the one
function, not second analysis tools:

- **porechop** also has `pigz` — Porechop shells out to it for parallel gzip.
- **whokaryote** also has `tiara` and `prodigal` — Whokaryote orchestrates both
  rather than reimplementing them. Note the channels: **`tiara` is on
  conda-forge, not bioconda**, which has no such package.

## Do you actually need these?

**Usually not.** Every nf-core module already declares its own single-tool
BioContainers/Seqera image, and `-profile docker` or `-profile singularity`
pulls those automatically. Those upstream images are built from the same bioconda
recipes, so they are the canonical "one tool, one image" artefacts and need no
maintenance from us.

Build the images here when you need something upstream cannot give you:

- an **institutional or air-gapped registry** you control
- a tool with **no upstream BioContainer** — `whokaryote` is exactly this case
- a container carrying the pipeline's own **`bin/` scripts** — `biopython` is
  this case: the code being run is ours, so the image has to be ours

## Build

```bash
# Workflow 1
docker build -t seabed-nanoplot:1.47.0   docker/nanoplot/
docker build -t seabed-seqkit:2.13.0     docker/seqkit/
docker build -t seabed-filtlong:0.2.1    docker/filtlong/
docker build -t seabed-porechop:0.2.4    docker/porechop/

# Workflow 2
docker build -t seabed-flye:2.9.5        docker/flye/
docker build -t seabed-bandage:0.9.0     docker/bandage/
docker build -t seabed-whokaryote:1.1.2  docker/whokaryote/
docker build -t seabed-biopython:1.84    docker/biopython/
```

Every build ends with a version or `--help` check, so a broken image fails at
build time instead of mid-pipeline. Measured sizes:

| Image | Size | | Image | Size |
|---|---|---|---|---|
| `seabed-seqkit` | 168 MB | | `seabed-porechop` | 619 MB |
| `seabed-filtlong` | 181 MB | | `seabed-flye` | 734 MB |
| `seabed-biopython` | 774 MB | | `seabed-nanoplot` | 2.18 GB |
| `seabed-bandage` | 2.35 GB (Qt) | | `seabed-whokaryote` | 2.59 GB (PyTorch) |

## Using them instead of the upstream images

The nf-core modules are unmodified, so the `container` directive is overridden
from config rather than by editing them. A ready-made profile does this:

```bash
nextflow run main.nf -profile local_containers,test
```

See the `local_containers` block in [`../nextflow.config`](../nextflow.config).
