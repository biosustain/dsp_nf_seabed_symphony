# nf-seabed-symphony

A [Nextflow](https://www.nextflow.io/) (DSL2) reimplementation of the
[seabed-symphony](https://github.com/felipevzps/seabed-symphony) metagenomics pipeline for the discovery of
biosynthetic gene clusters (BGCs) from Oxford Nanopore long reads.

The original pipeline is a series of 17 sequential bash scripts. This repository
translates it into a portable, resumable, containerised Nextflow workflow built
from [nf-core](https://nf-co.re/modules) modules.

---

## Status

| Workflow | Scope | Original steps | Status |
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

## Workflow 1 — Preprocessing & Quality Control

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
                        clean reads → Workflow 2
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

**One function, one tool, one image.**

By default the pipeline uses the single-tool image each nf-core module already
declares. These are built from the same bioconda recipes as the conda
environments, so `-profile docker` or `-profile singularity` pulls them
automatically and nothing needs building:

| Process | Tool | Image source |
|---|---|---|
| `NANOPLOT` | NanoPlot 1.47.0 | BioContainers |
| `SEQKIT_STATS` | SeqKit 2.13.0 | Seqera Containers |
| `FILTLONG` | Filtlong 0.2.1 | BioContainers |
| `PORECHOP_PORECHOP` | Porechop 0.2.4 | Seqera Containers |

[`docker/`](docker/) holds an equivalent one-tool-per-image Dockerfile for each,
pinned to the same versions. Build these only when you need something upstream
cannot provide — an institutional or air-gapped registry, a tool with no upstream
container (likely Whokaryote and GraphMB later), or an image carrying this
pipeline's own `bin/` scripts:

```bash
docker build -t seabed-nanoplot:1.47.0 docker/nanoplot/
```

See [`docker/README.md`](docker/README.md) for all four builds and for how to
point processes at them without editing the nf-core modules.

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
│   └── preprocessing_qc.nf      Workflow 1
├── modules/nf-core/             unmodified nf-core modules
│   ├── filtlong/
│   ├── nanoplot/
│   ├── porechop/porechop/
│   └── seqkit/stats/
└── docker/                      one-tool-per-image Dockerfiles
    ├── filtlong/
    ├── nanoplot/
    ├── porechop/
    └── seqkit/
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
- [ ] Workflow 2: metaFlye assembly, Whokaryote, prokaryotic contig extraction
- [ ] Workflow 3: multi-binner ensemble + DAS Tool + CheckM
- [ ] Workflow 4: GTDB-Tk, Bakta, antiSMASH, BiG-SCAPE
- [ ] nf-test unit tests per module
- [ ] Institutional/HPC profile for cluster execution
