nextflow.enable.dsl=2

params.bam     = "*.bam"
params.outdir  = "results"

process COUNT_READS {
    tag "${meta.id}"
    publishDir "${params.outdir}", mode: 'copy'

    input:
    tuple val(meta), path(bam)

    output:
    tuple val(meta), path("${meta.id}.flagstat.txt"), emit: flagstat
    tuple val(meta), path("${meta.id}.stats.txt"),    emit: stats

    script:
    /****************************************/
    """
    samtools flagstat ${bam} > ${meta.id}.flagstat.txt
    samtools stats ${bam} > ${meta.id}.stats.txt
    """
}

process COVERAGE {
    tag "${meta.id}"
    publishDir "${params.outdir}", mode: 'copy'

    input:
    tuple val(meta), path(bam)

    output:
    tuple val(meta), path("${meta.id}.coverage.txt"), emit: coverage

    script:
    """
    samtools coverage ${bam} -o ${meta.id}.coverage.txt
    """
}

process SUMMARIZE {
    publishDir "${params.outdir}", mode: 'copy'

    input:
    path flagstats
    path coverages

    output:
    path "summary.tsv"

    script:
    """
    summarize.py
    """
}

workflow {
    Channel
        .fromPath(params.bam, checkIfExists: true)
        .map { bam -> [ [id: bam.simpleName], bam ] }
        .set { bam_ch }

    COUNT_READS(bam_ch)
    COVERAGE(bam_ch)

    SUMMARIZE(
        COUNT_READS.out.flagstat.map { meta, f -> f }.collect(),
        COVERAGE.out.coverage.map { meta, f -> f }.collect()
    )
}
