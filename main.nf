nextflow.enable.dsl = 2

include { PREPROCESSING_QC } from './workflows/preprocessing_qc'

// ── Parameters ────────────────────────────────────────────────────────────────
params.input            = null
params.outdir           = 'results'
params.publish_dir_mode = 'copy'

// ── Validation ────────────────────────────────────────────────────────────────
def checkParams() {
    if (!params.input) {
        error "No input specified. Provide reads with --input 'path/to/*.fastq.gz'"
    }
}

// ── Workflow ──────────────────────────────────────────────────────────────────
workflow {
    checkParams()

    reads_ch = Channel
        .fromPath(params.input, checkIfExists: true)
        .map { file -> tuple([id: file.simpleName, single_end: true], file) }

    PREPROCESSING_QC(reads_ch)
}
