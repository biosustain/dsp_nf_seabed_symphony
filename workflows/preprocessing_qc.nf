// Module 1: Preprocessing & Quality Control
//
// Steps:
//   1a. NanoPlot (raw)         — read quality/length visualisation
//   1b. SeqKit stats (raw)     — summary statistics
//   2a. Filtlong --min_length  — remove reads shorter than 1 kb
//   2b. Filtlong --keep_percent — retain top 90 % quality reads
//   3.  Porechop               — strip Oxford Nanopore adapters
//   4a. NanoPlot (trimmed)     — post-trimming QC
//   4b. SeqKit stats (trimmed) — post-trimming statistics

include { NANOPLOT             } from '../modules/nf-core/nanoplot/main'
include { NANOPLOT as NANOPLOT_TRIMMED } from '../modules/nf-core/nanoplot/main'
include { SEQKIT_STATS                 } from '../modules/nf-core/seqkit/stats/main'
include { SEQKIT_STATS as SEQKIT_STATS_TRIMMED } from '../modules/nf-core/seqkit/stats/main'
include { FILTLONG as FILTLONG_MINLEN  } from '../modules/nf-core/filtlong/main'
include { FILTLONG as FILTLONG_QUALITY } from '../modules/nf-core/filtlong/main'
include { PORECHOP_PORECHOP            } from '../modules/nf-core/porechop/porechop/main'

workflow PREPROCESSING_QC {

    take:
    reads // channel: [ val(meta), path(reads) ]

    main:
    ch_versions = Channel.empty()

    // ── Step 1: Raw reads QC ─────────────────────────────────────────────────
    NANOPLOT ( reads )
    ch_versions = ch_versions.mix( NANOPLOT.out.versions.first() )

    SEQKIT_STATS ( reads )
    ch_versions = ch_versions.mix( SEQKIT_STATS.out.versions.first() )

    // ── Step 2: Length + quality filtering ───────────────────────────────────
    // First pass: remove reads < 1 000 bp (configured via ext.args in modules.config)
    FILTLONG_MINLEN ( reads )
    ch_versions = ch_versions.mix( FILTLONG_MINLEN.out.versions.first() )

    // Second pass: keep the top 90 % quality reads
    FILTLONG_QUALITY ( FILTLONG_MINLEN.out.reads )
    ch_versions = ch_versions.mix( FILTLONG_QUALITY.out.versions.first() )

    // ── Step 3: Adapter removal ───────────────────────────────────────────────
    PORECHOP_PORECHOP ( FILTLONG_QUALITY.out.reads )
    ch_versions = ch_versions.mix( PORECHOP_PORECHOP.out.versions.first() )

    // ── Step 4: Post-trimming QC ─────────────────────────────────────────────
    NANOPLOT_TRIMMED ( PORECHOP_PORECHOP.out.reads )
    ch_versions = ch_versions.mix( NANOPLOT_TRIMMED.out.versions.first() )

    SEQKIT_STATS_TRIMMED ( PORECHOP_PORECHOP.out.reads )
    ch_versions = ch_versions.mix( SEQKIT_STATS_TRIMMED.out.versions.first() )

    emit:
    reads    = PORECHOP_PORECHOP.out.reads   // clean reads ready for assembly
    versions = ch_versions
}
