#!/usr/bin/env python3
"""llm_c5_check.py - optional discovery (condition 5): how many scripts used a query, and the
false-clean rate among residue-case scripts that queried versus those that did not.
Run from the experiments/llm folder."""
import csv
from pathlib import Path
RES = Path(__file__).resolve().parent.parent.parent / "results" / "llm"
rows = [r for r in csv.DictReader((RES / "llm_scores.csv").open()) if r["condition"] == "5"]
print("model,scripts,queried,residue_scripts_queried,false_clean_queried,residue_scripts_not_queried,false_clean_not_queried")
for model in sorted({r["model"] for r in rows}):
    tag = model.replace(":", "_")
    g = [r for r in rows if r["model"] == model]
    q = lambda r: any((RES / "raw" / tag).glob(f"{r['instance']}_c5_t{r['trial']}_q*.sql"))
    queried = [r for r in g if q(r)]
    res_q = [r for r in queried if r["truth_clean"] == "0"]
    res_n = [r for r in g if r["truth_clean"] == "0" and not q(r)]
    print(",".join(map(str, [model, len(g), len(queried), len(res_q), sum(int(r["false_clean"]) for r in res_q),
                             len(res_n), sum(int(r["false_clean"]) for r in res_n)])))
