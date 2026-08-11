# nf-seabed-symphony

A [Nextflow](https://www.nextflow.io/) (DSL2) reimplementation of the
[seabed-symphony](https://github.com/felipevzps/seabed-symphony) metagenomics pipeline for the discovery of
biosynthetic gene clusters (BGCs) from Oxford Nanopore long reads.

The original pipeline is a series of 17 sequential bash scripts. This repository
translates it into a portable, resumable, containerised Nextflow workflow built
from [nf-core](https://nf-co.re/modules) modules.

---

## Status

| Module | Scope | Original steps | Status |
|---|---|---|---|
| 1 | Preprocessing & Quality Control | 1–4 | ✅ **implemented** |
| 2 | Metagenome Assembly & Annotation | 5–8 | ⬜ planned |
| 3 | Genome Binning & Quality Assessment | 9–11 | ⬜ planned |
| 4 | BGC Detection & Functional Analysis | 12–15 | ⬜ planned |

---

## Requirements

- **Java** 17 or later (Nextflow runs on the JVM)
- **Nextflow** ≥ 24.10 — the pipeline uses topic channels, `eval` outputs and
  native `process.resourceLimits`
- One execution backend: **Conda/Mamba**, **Docker**, or **Singularity/Apptainer**

```bash
# macOS, via Homebrew
brew install --cask temurin@21
curl -s https://get.nextflow.io | bash
```

---

## Quick start

Run the smoke test (downloads a small public dataset automatically):

```bash
nextflow run main.nf -profile conda,test
```

Run on your own data:

```bash
nextflow run main.nf -profile conda --input 'data/*.fastq.gz' --outdir results
```

Swap the execution backend by changing the profile:

```bash
nextflow run main.nf -profile docker      --input 'data/*.fastq.gz'
nextflow run main.nf -profile singularity --input 'data/*.fastq.gz'
```

### Parameters

| Parameter | Default | Description |
|---|---|---|
| `--input` | *(required)* | Glob or path to gzipped long-read FASTQ files |
| `--outdir` | `results` | Output directory |
| `--max_cpus` | `16` | Ceiling on CPUs per task |
| `--max_memory` | `128.GB` | Ceiling on memory per task |
| `--max_time` | `240.h` | Ceiling on runtime per task |

---

## Module 1 — Preprocessing & Quality Control

```
raw FASTQ
   ├── NanoPlot            (1a)  read length / quality plots
   ├── SeqKit stats        (1b)  summary statistics
   └── Filtlong            (2a)  --min_length 1000
         └── Filtlong      (2b)  --keep_percent 90
               └── Porechop (3)  adapter removal
                     ├── NanoPlot     (4a)  post-trim QC
                     └── SeqKit stats (4b)  post-trim statistics
                           │
                           ▼
                        clean reads → Module 2
```

### Tools

| Step | Tool | Version | Purpose |
|---|---|---|---|
| 1a, 4a | NanoPlot | 1.47.0 | Read length and quality visualisation |
| 1b, 4b | SeqKit | 2.13.0 | Read statistics table |
| 2a, 2b | Filtlong | 0.2.1 | Length and quality filtering |
| 3 | Porechop | 0.2.4 | Oxford Nanopore adapter removal |

Tool arguments live in [`conf/modules.config`](conf/modules.config) — edit them
there rather than in the module files, so the nf-core modules stay updatable.

---

## Output

```
results/
├── preprocessing/
│   ├── <sample>/<sample>.clean.fastq.gz   ← analysis-ready reads
│   └── logs/                              ← Filtlong + Porechop logs
├── qc/
│   ├── nanoplot/raw/<sample>/             ← HTML reports, PNG plots, NanoStats.txt
│   ├── nanoplot/trimmed/<sample>/
│   └── seqkit/
│       ├── <sample>.raw.tsv
│       └── <sample>.trimmed.tsv
└── pipeline_info/
    ├── software_versions.yml               ← every tool version used
    ├── execution_report.html
    ├── execution_timeline.html
    ├── execution_trace.txt
    └── pipeline_dag.html
```

---

## Test data

`-profile test` streams a **_Bacteroides fragilis_ ONT dataset** from the
[nf-core/test-datasets](https://github.com/nf-core/test-datasets) repository
(1 000 reads, ~33 kb mean read length, ~93 % of reads pass the 1 kb filter).
Nothing large is committed to this repository.

It is a *technical* test: it exercises every process, produces realistic
long-read length distributions, and completes in minutes. It is a single bacterial isolate, 
so it has no community structure to bin and few BGCs to find. 

---

## Containerisation

Two layers coexist:

**1. Per-tool containers (active by default).** Every nf-core module pins its own
BioContainers/Seqera image. `-profile docker` or `-profile singularity` pulls
them automatically — nothing needs building.

**2. Grouped images (in progress).** One image per module, so the pipeline can be
distributed as four self-contained units:

| Image | Module | Tools | Status |
|---|---|---|---|
| `seabed-qc` | 1 | NanoPlot, SeqKit, Filtlong, Porechop | [Dockerfile](docker/seabed-qc/Dockerfile) written |
| `seabed-assembly` | 2 | Flye, Whokaryote, BBMap, SAMtools | planned |
| `seabed-binning` | 3 | MetaBAT2, MaxBin2, CONCOCT, DAS Tool, CheckM | planned |
| `seabed-bgc` | 4 | GTDB-Tk, Bakta, antiSMASH, BiG-SCAPE | planned |

```bash
docker build -t seabed-qc:1.0.0 docker/seabed-qc/
```

Note that `seabed-qc` is **not yet wired into the pipeline** — the modules still
use their individual per-tool images. Grouped images become worthwhile mainly for
Module 4, where antiSMASH, Bakta and GTDB-Tk have heavy, conflict-prone
dependency trees.

---

## Repository layout

```
├── main.nf                      entry point; input channel + version collection
├── nextflow.config              params, profiles, resource ceilings, reports
├── modules.json                 nf-core module versions (managed by nf-core CLI)
├── conf/
│   ├── base.config              CPU/memory/time per process label
│   └── modules.config           tool arguments + publishing rules
├── workflows/
│   └── preprocessing_qc.nf      Module 1 subworkflow
├── modules/nf-core/             unmodified nf-core modules
│   ├── filtlong/
│   ├── nanoplot/
│   ├── porechop/porechop/
│   └── seqkit/stats/
└── docker/
    └── seabed-qc/Dockerfile
```

Modules are **unmodified** nf-core code. To update them later, install the
nf-core CLI and run:

```bash
pip install nf-core
nf-core modules update --all
```

---

## Roadmap

- [ ] Samplesheet input (CSV with sample ID, barcode, site, depth) — needed for
      multiplexed runs; the current glob input cannot carry per-sample metadata
- [ ] MultiQC report aggregating NanoPlot and SeqKit across samples
- [ ] Module 2: metaFlye assembly, Whokaryote, prokaryotic contig extraction
- [ ] Module 3: multi-binner ensemble + DAS Tool + CheckM
- [ ] Module 4: GTDB-Tk, Bakta, antiSMASH, BiG-SCAPE
- [ ] nf-test unit tests per module
- [ ] Institutional/HPC profile for cluster execution
