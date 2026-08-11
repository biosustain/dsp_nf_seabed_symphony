#!/usr/bin/env nextflow
//
// nf-seabed-symphony
// Nextflow implementation of the seabed-symphony marine metagenomics /
// BGC-discovery pipeline.
//
// Currently implemented:
//   Module 1 — Preprocessing & Quality Control
//
// Planned:
//   Module 2 — Metagenome Assembly & Annotation
//   Module 3 — Genome Binning & Quality Assessment
//   Module 4 — BGC Detection & Functional Analysis
//

include { PREPROCESSING_QC } from './workflows/preprocessing_qc'

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

    // ── Module 1 ─────────────────────────────────────────────────────────────
    PREPROCESSING_QC ( ch_reads )

    // ── Software versions ────────────────────────────────────────────────────
    // Every nf-core module publishes to the `versions` topic. Collect the
    // whole set once here and write a single reproducibility record.
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
