#!/usr/bin/env python3
"""Collect per-sample total reads and average coverage into summary.tsv."""
import os
import re
import glob

TOTAL_RE = re.compile(r"(\d+) \+ \d+ in total")

rows = []
for f in sorted(glob.glob("*.flagstat.txt")):
    sample = f.replace(".flagstat.txt", "")
    total_reads = 0
    with open(f) as fh:
        for line in fh:
            m = TOTAL_RE.match(line)
            if m:
                total_reads = int(m.group(1))
                break

    avg_cov = "N/A"
    cov_file = sample + ".coverage.txt"
    if os.path.exists(cov_file):
        covs, lengths = [], []
        with open(cov_file) as ch:
            next(ch)  # header
            for line in ch:
                parts = line.rstrip("\n").split("\t")
                if len(parts) >= 7:
                    lengths.append(int(parts[2]))
                    covs.append(float(parts[6]))
        total_len = sum(lengths)
        if covs and total_len:
            weighted = sum(c * l for c, l in zip(covs, lengths)) / total_len
            avg_cov = f"{weighted:.2f}x"

    rows.append((sample, total_reads, avg_cov))

with open("summary.tsv", "w") as out:
    out.write("sample\ttotal_reads\tavg_coverage\n")
    for sample, reads, cov in rows:
        out.write(f"{sample}\t{reads}\t{cov}\n")

print(f"Summary written to summary.tsv ({len(rows)} sample(s))")
