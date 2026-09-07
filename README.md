# BAM QC Pipeline

A Nextflow DSL2 pipeline that reports **total read count** and **average coverage** for one or more BAM files.

## Requirements
- Nextflow >= 23.04
- Docker (or Singularity)
- BAM files must be indexed (`.bam` + `.bam.bai`)

## Usage

```bash
# Single BAM
nextflow run main.nf --bam "/path/to/sample.bam" --outdir results

# Multiple BAMs (glob)
nextflow run main.nf --bam "/data/*.bam" --outdir results
```

## Outputs

| File | Description |
|-----|-------------|
| `*.flagstat.txt` | samtools flagstat per sample |
| `*.stats.txt` | samtools stats per sample |
| `*.coverage.txt` | per-chromosome coverage table |
| `summary.tsv` | **total reads + avg coverage per sample** |

## Summary format

```
sample    total_reads    avg_coverage
sample1   45231890       28.4x
sample2   51002344       31.7x
```
