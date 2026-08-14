#!/usr/bin/env nextflow
//
// nf-seabed-symphony
// Nextflow implementation of the seabed-symphony marine metagenomics /
// BGC-discovery pipeline.
//
// Currently implemented:
//   Workflow 1 — Preprocessing & Quality Control
//   Workflow 2 — Metagenome Assembly & Annotation
//
// Planned:
//   Workflow 3 — Genome Binning & Quality Assessment
//   Workflow 4 — BGC Detection & Functional Analysis
//

include { PREPROCESSING_QC    } from './workflows/preprocessing_qc'
include { ASSEMBLY_ANNOTATION } from './workflows/assembly_annotation'

workflow {

    if ( !params.input ) {
        error """
        No input given. Provide long-read FASTQ files with --input, e.g.

            nextflow run main.nf -profile conda --input 'data/*.fastq.gz'

        Or run the bundled smoke test:

            nextflow run main.nf -profile conda,test
        """.stripIndent()
    }

    // ── Input channel ────────────────────────────────────────────────────────
    // One FASTQ per sample. `single_end: true` is required by the nf-core
    // FILTLONG module even though no short reads are supplied.
    ch_reads = Channel
        .fromPath( params.input, checkIfExists: true )
        .map { fastq -> [ [ id: fastq.simpleName, single_end: true ], fastq ] }

    // ── Workflow 1 ───────────────────────────────────────────────────────────
    PREPROCESSING_QC ( ch_reads )

    // ── Workflow 2 ───────────────────────────────────────────────────────────
    // Assembly is expensive; --skip_assembly stops after QC.
    if ( !params.skip_assembly ) {
        ASSEMBLY_ANNOTATION ( PREPROCESSING_QC.out.reads )
    }

    // ── Software versions ────────────────────────────────────────────────────
    // Every module publishes to the `versions` topic. Collect the whole set
    // once here and write a single reproducibility record.
    Channel.topic( 'versions' )
        .map { process, name, version -> "${name}: ${version}" }
        .unique()
        .collectFile(
            name     : 'software_versions.yml',
            storeDir : "${params.outdir}/pipeline_info",
            newLine  : true,
            sort     : true
        )
}
