# popgen-pipeline

Nextflow (DSL2) pipeline that takes a multi-sample VCF and computes:

1. **Runs of Homozygosity (ROH)** per sample
2. **Pairwise kinship / relatedness** — `plink2 --make-king-table`
3. A **summary report** (CSV + plots): FROH per sample, relationship degree per pair

Built and tested on (1000 Genomes chr22:20-30Mb
slice, 9 samples) task from Strand Life Science, but works on any bgzipped, indexed multi-sample VCF.

## Pipeline

```
   VCF + .tbi ──► QC_FILTER ──► ROH_ANALYSIS ──┐
                       │                                          ├──► REPORT
                       └──────────► LD_PRUNE ──► KINSHIP ─────────┘
```

Each box is its own Nextflow process, running in its own Docker container.

## Prerequisites

- Nextflow >= 23.04
- Docker
- Build the report image once (not pushed anywhere, built from the Dockerfile in this repo):

  ```bash
  In Repo containers/Dockerfile
  docker build -t popgen-report:1.0 .
  ```

`plink`/`plink2` are pulled automatically on first run.

## Running

```bash
git clone <this-repo-url>
cd popgen-pipeline/container
docker build -t popgen-report:1.0 .
cd ../
nextflow run main.nf -profile docker \
  --vcf /path/to/popgen_test_chr22.vcf.gz \
  --outdir results/
```

VCF needs a matching `.tbi` next to it (or pass `--vcf_index`).
`nextflow run main.nf --help` lists all params.

Test data (`popgen_test_chr22.vcf.gz`) isn't committed here — drop it in
the repo root or point `--vcf` at wherever you have it.

## Parameters

Defaults match the assessment's recommended thresholds (`nextflow.config`),
all overridable on the CLI.

| Stage | Flag | Default | Meaning |
|---|---|---|---|
| QC | `--maf` | 0.05 | Min minor allele frequency |
| QC | `--geno` | 0.05 | Max per-variant missingness |
| QC | `--mind` | 0.10 | Max per-sample missingness |
| QC | `--hwe` | 1e-4 | Hardy-Weinberg p-value floor |
| ROH | `--homozyg_kb` | 200 | Min segment length (kb) |
| ROH | `--homozyg_snp` | 30 | Min SNPs per segment |
| ROH | `--homozyg_density` | 50 | Max kb/SNP density |
| ROH | `--homozyg_gap` | 1000 | Max gap between SNPs (kb) |
| ROH | `--homozyg_window_snp/het/missing` | 30/1/5 | Sliding window size, allowed hets/missing |
| ROH | `--froh_denom_mb` | 10 | Region size (Mb) used to normalize FROH |
| LD | `--ld_window/step/r2` | 50/5/0.2 | `--indep-pairwise` params |
| Kinship | `--king_cutoff` | 0.0442 | Min kinship coefficient reported |

Two things specific to this 9-sample test panel mentioned in assessment manual:
- `--bad-ld` on `LD_PRUNE`: plink2 refuses `--indep-pairwise` below 50
  samples, this forces it through.
- `--set-all-var-ids` + `--rm-dup force-first` in `QC_FILTER`: 1000 Genomes
  VCFs have `.` variant IDs / multiallelic overlaps that break
  `--indep-pairwise`'s unique-ID requirement.

## Outputs

```
results/
├── qc/          QC'd plink fileset + logs
├── ld_prune/     prune.in
├── roh/         .hom / .hom.indiv
├── kinship/     .kin0
├── report/
│   ├── roh_summary.csv       Sample, ROH_segments, Total_ROH_kb, FROH, FROH_percent
│   ├── kinship_summary.csv   Sample1, Sample2, Kinship, Relationship
│   └── summary_plots.png
└── pipeline_info/  nextflow executions report/timeline/trace
```

Kinship classification (KING thresholds):

| Kinship (φ) | Degree |
|---|---|
| φ > 0.354 | Duplicate / twin |
| 0.177 - 0.354 | 1st-degree |
| 0.0884 - 0.177 | 2nd-degree |
| 0.0442 - 0.0884 | 3rd-degree |
| < 0.0442 | Unrelated |

## Containers

| Process | Image |
|---|---|
| QC_FILTER, CONVERT_TO_BED, LD_PRUNE, KINSHIP | `ghcr.io/pgscatalog/plink2:2.00a5.10` |
| ROH_ANALYSIS | `quay.io/biocontainers/plink:1.90b6.21--h779adbc_1` |
| REPORT | `popgen-report:1.0` (built locally, `containers/report/Dockerfile`) |

ROH uses plink1.9 instead of plink2 since `--homozyg` there is the original,
more predictable implementation.

## Layout

```
popgen-pipeline/
├── main.nf
├── nextflow.config
├── modules/
│   ├── qc_filter.nf
│   ├── roh_analysis.nf
│   ├── ld_prune.nf
│   ├── kinship.nf
│   └── report.nf
├── bin/generate_report.py
├── containers/Dockerfile
└── README.md
```
Plot generated from sample dataset on FROH & Kinship relationship degree

<img width="2100" height="900" alt="summary_plots" src="https://github.com/user-attachments/assets/3a42ce32-580a-4211-89b8-fba2268dd410" />

