#!/usr/bin/env python3
"""llm_model_check.py - per-model look-or-not analysis for every model in llm_scores.csv.
Run from the experiments/llm folder:  python3 llm_model_check.py

For residue-case scripts it reports, per model:
  c1  schema only: scripts whose own text mentions CDC (cdc.) or a history/temporal table,
      and false clean among scripts that do / do not.
  c4  discovery: scripts whose discovery query mentions cdc, and false clean among them / the rest.
  c5  optional discovery: scripts that ran at least one query, and false clean among them / the rest.
Gemini trials 6-10 (run for some cases before its daily quota stopped the run) are excluded,
so every model is counted over the trials reported in the paper."""
import csv, re
from pathlib import Path

RES = Path(__file__).resolve().parent.parent.parent / "results" / "llm"
TRIAL_CAP = {"gemini-3.1-pro-preview": 5}
rows = [r for r in csv.DictReader((RES / "llm_scores.csv").open())
        if r["condition"] in ("1", "4", "5") and r["truth_clean"] == "0"
        and int(r["trial"]) <= TRIAL_CAP.get(r["model"], 99)]


def read(p):
    return p.read_text(errors="replace").lower() if p.exists() else ""


print("model,condition,residue_scripts,looked,false_clean_looked,not_looked,false_clean_not_looked")
for model in sorted({r["model"] for r in rows}):
    raw = RES / "raw" / model.replace(":", "_")
    for cond in ("1", "4", "5"):
        g = [r for r in rows if r["model"] == model and r["condition"] == cond]
        if not g:
            continue
        looked = []
        for r in g:
            stem = f"{r['instance']}_c{cond}_t{r['trial']}"
            if cond == "1":
                txt = read(raw / f"{stem}.sql")
                hit = bool(re.search(r"\bcdc\b|history|temporal|sys\.tables|information_schema", txt))
            elif cond == "4":
                hit = "cdc" in read(raw / f"{stem}_q.sql")
            else:
                hit = any(raw.glob(f"{stem}_q*.sql"))
            looked.append(hit)
        fl = sum(int(r["false_clean"]) for r, h in zip(g, looked) if h)
        fn = sum(int(r["false_clean"]) for r, h in zip(g, looked) if not h)
        n = sum(looked)
        print(",".join(map(str, [model, cond, len(g), n, fl, len(g) - n, fn])))
