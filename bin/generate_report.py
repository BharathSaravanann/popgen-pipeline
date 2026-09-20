#!/usr/bin/env python3
"""
Inputs plink's .hom.indiv and .kin0 output. Called by modules/report.nf.
"""
import argparse
import os

import pandas as pd
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

CATEGORY_COLORS = {
    "Duplicate/Identical twin": "#8B0000",  # dark red
    "1st degree":               "#E24A33",  # red-orange
    "2nd degree":                "#F5B041",  # orange
    "3rd degree":                "#F4D03F",  # yellow
    "Unrelated":                 "#5DADE2",  # blue
}

KINSHIP_THRESHOLDS = [
    (0.354, "1st-degree cutoff"),
    (0.177, "2nd-degree cutoff"),
    (0.0884, "3rd-degree cutoff"),
    (0.0442, "Unrelated cutoff"),
]


def classify_kinship(phi):
    if phi > 0.354:
        return "Duplicate/Identical twin"
    elif phi >= 0.177:
        return "1st degree"
    elif phi >= 0.0884:
        return "2nd degree"
    elif phi >= 0.0442:
        return "3rd degree"
    else:
        return "Unrelated"


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--hom-indiv", required=True)
    ap.add_argument("--kin0", required=True)
    ap.add_argument("--froh-denom-mb", type=float, default=10.0)
    ap.add_argument("--outdir", default=".")
    args = ap.parse_args()

    os.makedirs(args.outdir, exist_ok=True)
    region_kb = args.froh_denom_mb * 1000.0

    roh = pd.read_csv(args.hom_indiv, sep=r"\s+")

    roh["FROH"] = roh["KB"] / region_kb
    roh["FROH_PERCENT"] = roh["FROH"] * 100

    roh_summary = roh[[
        "IID",
        "NSEG",
        "KB",
        "FROH",
        "FROH_PERCENT"
    ]].copy()

    roh_summary.columns = [
        "Sample",
        "ROH_segments",
        "Total_ROH_kb",
        "FROH",
        "FROH_percent"
    ]
    roh_summary = roh_summary.sort_values("FROH", ascending=False)

    roh_summary.to_csv(
        os.path.join(args.outdir, "roh_summary.csv"),
        index=False
    )

    king = pd.read_csv(args.kin0, sep=r"\s+")

    king["Relationship"] = king["KINSHIP"].apply(classify_kinship)

    king_summary = king[[
        "IID1",
        "IID2",
        "KINSHIP",
        "Relationship"
    ]].copy()

    king_summary.columns = [
        "Sample1",
        "Sample2",
        "Kinship",
        "Relationship"
    ]
    king_summary = king_summary.sort_values("Kinship", ascending=False)

    king_summary.to_csv(
        os.path.join(args.outdir, "kinship_summary.csv"),
        index=False
    )

    print("ROH summary:")
    print(roh_summary.to_string(index=False))

    print("\nKinship summary:")
    print(king_summary.to_string(index=False))

    fig, axes = plt.subplots(1, 2, figsize=(14, 6))

    # Panel 1: per-sample FROH bar chart
    ax = axes[0]
    ax.bar(roh_summary["Sample"], roh_summary["FROH_percent"], color="#4C72B0")
    ax.set_xlabel("Sample")
    ax.set_ylabel(f"FROH % (ROH length / {args.froh_denom_mb:g} Mb)")
    ax.set_title("Inbreeding coefficient (FROH) per sample")
    ax.tick_params(axis="x", rotation=45)

    # Panel 2: one bar per pair, colored by relationship category
    ax2 = axes[1]
    pairs = king_summary.sort_values("Kinship", ascending=True)
    pair_labels = pairs["Sample1"] + " – " + pairs["Sample2"]
    bar_colors = [CATEGORY_COLORS[r] for r in pairs["Relationship"]]

    ax2.barh(pair_labels, pairs["Kinship"], color=bar_colors)
    for x, label in KINSHIP_THRESHOLDS:
        ax2.axvline(x, color="gray", linestyle="--", linewidth=0.8)
    ax2.set_xlabel("Kinship coefficient (\u03c6) — higher = more closely related")
    ax2.set_title("Pairwise relatedness")
    ax2.tick_params(axis="y", labelsize=8)

    present = [c for c in CATEGORY_COLORS if c in set(pairs["Relationship"])]
    handles = [plt.Rectangle((0, 0), 1, 1, color=CATEGORY_COLORS[c]) for c in present]
    ax2.legend(handles, present, loc="lower right", fontsize=8, title="Relationship")

    fig.tight_layout()
    fig.savefig(os.path.join(args.outdir, "summary_plots.png"), dpi=150)


if __name__ == "__main__":
    main()
