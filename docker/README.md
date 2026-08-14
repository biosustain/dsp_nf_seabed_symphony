# Container images

One function, one tool, one image — the nf-core convention.

| Directory | Image | Tool | Version | Used by |
|---|---|---|---|---|
| [`nanoplot/`](nanoplot/Dockerfile) | `seabed-nanoplot` | NanoPlot | 1.47.0 | `NANOPLOT`, `NANOPLOT_TRIMMED` |
| [`seqkit/`](seqkit/Dockerfile) | `seabed-seqkit` | SeqKit | 2.13.0 | `SEQKIT_STATS`, `SEQKIT_STATS_TRIMMED` |
| [`filtlong/`](filtlong/Dockerfile) | `seabed-filtlong` | Filtlong | 0.2.1 | `FILTLONG_MINLEN`, `FILTLONG_QUALITY` |
| [`porechop/`](porechop/Dockerfile) | `seabed-porechop` | Porechop | 0.2.4 | `PORECHOP_PORECHOP` |

Each image installs exactly one analysis tool, pinned to the same version as the
corresponding `modules/nf-core/<tool>/environment.yml`. If you bump a module,
bump its Dockerfile to match.

**Scope:** only Workflow 1's tools have Dockerfiles here. Workflow 2 (Flye,
Bandage, Whokaryote, Biopython) runs entirely on the upstream single-tool images
its modules declare, which is the recommended path — see below.

## Do you actually need these?

**Usually not.** Every nf-core module already declares its own single-tool
BioContainers/Seqera image, and `-profile docker` or `-profile singularity`
pulls those automatically. Those upstream images are built straight from the
same bioconda recipes, so they are the canonical "one tool, one image" artefacts
and require no maintenance from us.

Build the images here when you need something upstream cannot give you:

- an **institutional or air-gapped registry** you control
- a tool with **no upstream BioContainer** (likely for Whokaryote and GraphMB in
  later workflows)
- a container carrying the pipeline's own **`bin/` helper scripts**

## Build

```bash
docker build -t seabed-nanoplot:1.47.0 docker/nanoplot/
docker build -t seabed-seqkit:2.13.0   docker/seqkit/
docker build -t seabed-filtlong:0.2.1  docker/filtlong/
docker build -t seabed-porechop:0.2.4  docker/porechop/
```

Each build ends with a version check, so a broken image fails at build time
instead of mid-pipeline.

## Using them instead of the upstream images

The modules are unmodified nf-core code, so override the `container` directive
from config rather than editing them. Add a profile to `nextflow.config`:

```groovy
profiles {
    local_containers {
        docker.enabled = true
        process {
            withName: 'PREPROCESSING_QC:NANOPLOT|PREPROCESSING_QC:NANOPLOT_TRIMMED' {
                container = 'seabed-nanoplot:1.47.0'
            }
            withName: 'PREPROCESSING_QC:SEQKIT_STATS|PREPROCESSING_QC:SEQKIT_STATS_TRIMMED' {
                container = 'seabed-seqkit:2.13.0'
            }
            withName: 'PREPROCESSING_QC:FILTLONG_MINLEN|PREPROCESSING_QC:FILTLONG_QUALITY' {
                container = 'seabed-filtlong:0.2.1'
            }
            withName: 'PREPROCESSING_QC:PORECHOP_PORECHOP' {
                container = 'seabed-porechop:0.2.4'
            }
        }
    }
}
```

```bash
nextflow run main.nf -profile local_containers,test
```
