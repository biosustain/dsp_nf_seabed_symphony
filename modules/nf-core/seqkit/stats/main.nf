process SEQKIT_STATS {
    tag "$meta.id"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/seqkit:2.8.2--h9ee0642_0' :
        'biocontainers/seqkit:2.8.2--h9ee0642_0' }"

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("*.txt"), emit: stats
    path  "versions.yml"          , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args   = task.ext.args   ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    seqkit \\
        stats \\
        --all \\
        $args \\
        ${reads} \\
        > ${prefix}.seqkit.stats.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        seqkit: \$(seqkit version 2>&1 | sed 's/seqkit v//')
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.seqkit.stats.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        seqkit: \$(seqkit version 2>&1 | sed 's/seqkit v//')
    END_VERSIONS
    """
}
