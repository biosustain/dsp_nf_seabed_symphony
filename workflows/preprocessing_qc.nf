//
// Workflow 1: Preprocessing & Quality Control
//
// Faithful translation of seabed-symphony steps 1-4:
//   1a. NanoPlot (raw)          — read length / quality visualisation
//   1b. SeqKit stats (raw)      — summary statistics table
//   2a. Filtlong --min_length   — discard reads shorter than 1 kb
//   2b. Filtlong --keep_percent — retain the best 90 % of remaining reads
//   3.  Porechop                — strip Oxford Nanopore adapters
//   4a. NanoPlot (trimmed)      — post-trimming QC
//   4b. SeqKit stats (trimmed)  — post-trimming statistics
//
// Note on ordering: the original bash pipeline filters *before* removing
// adapters, and that order is reproduced here. See README for the caveat.
//
// Software versions are emitted by each module to the `versions` topic and
// collected once in main.nf — no per-module version plumbing is needed.
//

include { NANOPLOT                             } from '../modules/nf-core/nanoplot/main'
include { NANOPLOT as NANOPLOT_TRIMMED         } from '../modules/nf-core/nanoplot/main'
include { SEQKIT_STATS                         } from '../modules/nf-core/seqkit/stats/main'
include { SEQKIT_STATS as SEQKIT_STATS_TRIMMED } from '../modules/nf-core/seqkit/stats/main'
include { FILTLONG as FILTLONG_MINLEN          } from '../modules/nf-core/filtlong/main'
include { FILTLONG as FILTLONG_QUALITY         } from '../modules/nf-core/filtlong/main'
include { PORECHOP_PORECHOP                    } from '../modules/nf-core/porechop/porechop/main'

workflow PREPROCESSING_QC {

    take:
    ch_reads // channel: [ val(meta), path(reads) ]

    main:

    // ── Step 1: QC of the raw reads ──────────────────────────────────────────
    NANOPLOT     ( ch_reads )
    SEQKIT_STATS ( ch_reads )

    // ── Step 2: Length then quality filtering ────────────────────────────────
    // nf-core FILTLONG takes [ meta, shortreads, longreads ]. This is a
    // long-read-only pipeline, so an empty list is passed for shortreads.
    FILTLONG_MINLEN (
        ch_reads.map { meta, reads -> [ meta, [], reads ] }
    )

    FILTLONG_QUALITY (
        FILTLONG_MINLEN.out.reads.map { meta, reads -> [ meta, [], reads ] }
    )

    // ── Step 3: Adapter removal ──────────────────────────────────────────────
    PORECHOP_PORECHOP ( FILTLONG_QUALITY.out.reads )

    // ── Step 4: QC of the cleaned reads ──────────────────────────────────────
    NANOPLOT_TRIMMED     ( PORECHOP_PORECHOP.out.reads )
    SEQKIT_STATS_TRIMMED ( PORECHOP_PORECHOP.out.reads )

    emit:
    reads         = PORECHOP_PORECHOP.out.reads    // clean reads → Workflow 2 (assembly)
    nanoplot_raw  = NANOPLOT.out.txt               // NanoStats.txt, raw
    nanoplot_trim = NANOPLOT_TRIMMED.out.txt       // NanoStats.txt, trimmed
    stats_raw     = SEQKIT_STATS.out.stats         // SeqKit .tsv, raw
    stats_trim    = SEQKIT_STATS_TRIMMED.out.stats // SeqKit .tsv, trimmed
    filtlong_log  = FILTLONG_QUALITY.out.log
    porechop_log  = PORECHOP_PORECHOP.out.log
}
