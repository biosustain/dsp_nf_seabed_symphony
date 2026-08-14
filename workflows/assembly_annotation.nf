//
// Workflow 2: Metagenome Assembly & Annotation
//
// Translation of seabed-symphony steps 5-8:
//   5.  metaFlye   — metagenome assembly of the cleaned long reads
//   6.  Bandage    — render the assembly graph (see note below)
//   7.  Whokaryote — classify contigs as prokaryotic or eukaryotic
//   8.  extractContigsFromWhokaryote.py — split the assembly by domain
//
// Note on the fork after assembly: Flye emits two *different* files, so the two
// branches do not share an input. Bandage consumes the assembly GRAPH
// (assembly_graph.gfa) while Whokaryote consumes the CONTIGS (assembly.fasta).
//
// Note on Bandage: the original pipeline never scripted this step —
// workflow/6_bandage/ contains only hand-exported graph.png files, produced
// through the Bandage GUI. Automating it here is an addition, not a translation.
//
// Note on step 8: the original runs the extraction script twice, once with --p
// for prokaryotes and once with --e for eukaryotes. Both are reproduced. Only
// the prokaryotic contigs continue to Workflow 3; the eukaryotic ones are kept
// as a published by-product.
//

include { FLYE                                                   } from '../modules/nf-core/flye/main'
include { BANDAGE_IMAGE                                          } from '../modules/nf-core/bandage/image/main'
include { WHOKARYOTE                                             } from '../modules/local/whokaryote/main'
include { EXTRACTCONTIGSFROMWHOKARYOTE as EXTRACT_PROKARYOTE     } from '../modules/local/extractcontigsfromwhokaryote/main'
include { EXTRACTCONTIGSFROMWHOKARYOTE as EXTRACT_EUKARYOTE      } from '../modules/local/extractcontigsfromwhokaryote/main'

workflow ASSEMBLY_ANNOTATION {

    take:
    ch_reads // channel: [ val(meta), path(reads) ] — cleaned reads from Workflow 1

    main:

    // ── Step 5: metaFlye assembly ────────────────────────────────────────────
    // `--meta` and `--iterations` come from conf/modules.config; the read-type
    // mode is a separate module input and must be one of Flye's accepted flags.
    // .toString() matters: the module validates `mode` with List.contains(), and
    // a GString never equals a String, so an interpolated value would always fail.
    FLYE ( ch_reads, "--${params.flye_read_type}".toString() )

    // ── Step 6: assembly graph visualisation ─────────────────────────────────
    // Takes the GFA graph, not the contigs. The module decompresses it itself.
    ch_graph_png = Channel.empty()
    ch_graph_svg = Channel.empty()

    if ( !params.skip_bandage ) {
        BANDAGE_IMAGE ( FLYE.out.gfa )
        ch_graph_png = BANDAGE_IMAGE.out.png
        ch_graph_svg = BANDAGE_IMAGE.out.svg
    }

    // ── Step 7: prokaryote / eukaryote classification ────────────────────────
    // Takes the contigs FASTA.
    WHOKARYOTE ( FLYE.out.fasta )

    // ── Step 8: split the assembly by domain ─────────────────────────────────
    // join() on meta keeps each sample's assembly paired with its own headers.
    EXTRACT_PROKARYOTE (
        FLYE.out.fasta.join( WHOKARYOTE.out.prokaryote_headers ),
        'prokaryote'
    )

    EXTRACT_EUKARYOTE (
        FLYE.out.fasta.join( WHOKARYOTE.out.eukaryote_headers ),
        'eukaryote'
    )

    emit:
    prokaryote_contigs = EXTRACT_PROKARYOTE.out.contigs // → Workflow 3 (binning)
    eukaryote_contigs  = EXTRACT_EUKARYOTE.out.contigs  // by-product
    assembly           = FLYE.out.fasta
    gfa                = FLYE.out.gfa
    assembly_info      = FLYE.out.txt
    assembly_log       = FLYE.out.log
    graph_png          = ch_graph_png
    graph_svg          = ch_graph_svg
    whokaryote_results = WHOKARYOTE.out.results
}
