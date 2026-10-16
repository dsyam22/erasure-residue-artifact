#!/usr/bin/env python3
"""llm_discovery_check.py - what did the models query in the discovery condition (4)?
Run from the experiments/llm folder. Reads ../../results/llm/raw/<model>/<case>_c4_t<n>_q.sql/.out and
llm_scores.csv. For the cases with a CDC change table (i1, i3, i4, i6) it reports, per model and
outcome, whether the model's own query could have shown the change table: whether the query
text mentions cdc, and whether the change table's name (_CT) appears in the query output."""
import csv, re
from pathlib import Path
RES = Path(__file__).resolve().parent.parent.parent / "results" / "llm"
scores = {(r["model"], r["instance"], r["trial"]): r for r in csv.DictReader((RES / "llm_scores.csv").open())
          if r["condition"] == "4"}
tags = {"gemma4:e4b": "gemma4_e4b", "deepseek-flash": "deepseek-flash", "deepseek-v4-pro": "deepseek-v4-pro"}
print("model,outcome,scripts,query_mentions_cdc,ct_in_query_output,query_mentions_temporal_or_history")
for model, tag in tags.items():
    groups = {}
    for inst in ("i1", "i3", "i4", "i6"):
        for t in range(1, 11):
            r = scores.get((model, inst, str(t)))
            q = RES / "raw" / tag / f"{inst}_c4_t{t}_q.sql"
            if not r or not q.exists():
                continue
            out = (RES / "raw" / tag / f"{inst}_c4_t{t}_q.out").read_text(errors="replace")
            qs = q.read_text(errors="replace").lower()
            outcome = ("false_clean" if r["false_clean"] == "1" else
                       "did_not_run" if r["parseable"] == "0" else
                       "found_all" if r["recall"] == "1.0" else "found_some")
            g = groups.setdefault(outcome, [0, 0, 0, 0])
            g[0] += 1
            g[1] += "cdc" in qs
            g[2] += bool(re.search(r"_CT\b", out))
            g[3] += bool(re.search(r"temporal|history", qs))
    for outcome, g in sorted(groups.items()):
        print(",".join(map(str, [model, outcome] + g)))
