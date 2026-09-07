nextflow.enable.dsl=2

params.bam     = "*.bam"
params.outdir  = "results"

process COUNT_READS {
    tag "${meta.id}"
    publishDir "${params.outdir}", mode: 'copy'

    input:
    tuple val(meta), path(bam), path(bai)

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
    tuple val(meta), path(bam), path(bai)

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
    #!/usr/bin/env python3
    import os, re, glob

    rows = []
    for f in sorted(glob.glob("*.flagstat.txt")):
        sample = f.replace(".flagstat.txt", "")
        total_reads = 0
        with open(f) as fh:
            for line in fh:
                m = re.match(r"(\d+) \+ \d+ in total", line)
                if m:
                    total_reads = int(m.group(1))
                    break
        avg_cov = "N/A"
        cov_file = sample + ".coverage.txt"
        if os.path.exists(cov_file):
            covs, lengths = [], []
            with open(cov_file) as ch:
                next(ch)
                for line in ch:
                    parts = line.strip().split("\t")
                    if len(parts) >= 7:
                        lengths.append(int(parts[2]))
                        covs.append(float(parts[6]))
            if covs:
                total_len = sum(lengths)
                avg_cov = f"{sum(c*l for c,l in zip(covs,lengths)) / total_len:.2f}x"
        rows.append((sample, total_reads, avg_cov))

    with open("summary.tsv", "w") as out:
        out.write("sample\ttotal_reads\tavg_coverage\n")
        for sample, reads, cov in rows:
            out.write(f"{sample}\t{reads}\t{cov}\n")
    print("Summary written to summary.tsv")
    """
}

workflow {
    Channel
        .fromFilePairs(params.bam, flat: true)
        .map { id, bam, bai -> [ [id: id], bam, bai ] }
        .set { bam_ch }

    COUNT_READS(bam_ch)
    COVERAGE(bam_ch)

    SUMMARIZE(
        COUNT_READSs.out.flagstat.map { meta, f -> f }.collect(),
        COVERAGE.out.coverage.map { meta, f -> f }.collect()
    )
}
