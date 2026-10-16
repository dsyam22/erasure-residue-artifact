#!/usr/bin/env python3
"""llm_label.py - human check of the automated scoring in the LLM study.

Run from the experiments/llm folder.
  python3 llm_label.py sample    draw 45 scripts (5 per case) into results/llm/label_sheet.csv
  python3 llm_label.py label     show each script's output and record your reading of it
  python3 llm_label.py agree     compare your labels with the automated verdict
Add --discovery to any command for a second, separate sheet of 27 scripts (3 per case) drawn
from the discovery conditions 4 and 5: results/llm/label_sheet_discovery.csv

You label what the script's OUTPUT says, without seeing the automated score:
  f = FOUND     the output lists at least one  object|count  row with a count above 0
  c = CLEAN     the output lists object|count rows and every count is 0
  u = UNUSABLE  the output has no object|count rows at all (only errors, or nothing)
"""
import csv, random, re, sys
from pathlib import Path

RES = Path(__file__).resolve().parent.parent.parent / "results" / "llm"
DISCOVERY = "--discovery" in sys.argv
SHEET = RES / ("label_sheet_discovery.csv" if DISCOVERY else "label_sheet.csv")
COLS = ["model", "instance", "condition", "trial", "human_label"]
NAMES = {"f": "FOUND", "c": "CLEAN", "u": "UNUSABLE"}


def out_path(r):
    tag = re.sub(r"[^\w.-]", "_", r["model"])
    return RES / "raw" / tag / f"{r['instance']}_c{r['condition']}_t{r['trial']}.out"


def load_scores():
    rows = list(csv.DictReader((RES / "llm_scores.csv").open()))
    return [r for r in rows if not r["model"].startswith("baseline")]


def cmd_sample():
    if SHEET.exists():
        sys.exit(f"{SHEET} already exists; not overwriting your labels.")
    rng = random.Random(2027)
    by_case = {}
    for r in load_scores():
        if DISCOVERY and r["condition"] not in ("4", "5"):
            continue
        if DISCOVERY and r["model"] == "deepseek-v4-pro-thinking" and int(r["trial"]) > 5:
            continue
        by_case.setdefault(r["instance"], []).append(r)
    picked = []
    for inst in sorted(by_case):
        picked += rng.sample(by_case[inst], 3 if DISCOVERY else 5)
    rng.shuffle(picked)
    with SHEET.open("w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=COLS)
        w.writeheader()
        for r in picked:
            w.writerow({k: r.get(k, "") for k in COLS})
    print(f"Wrote {len(picked)} rows to {SHEET}")


def read_sheet():
    return list(csv.DictReader(SHEET.open()))


def write_sheet(rows):
    with SHEET.open("w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=COLS)
        w.writeheader()
        w.writerows(rows)


def cmd_label():
    rows = read_sheet()
    todo = [r for r in rows if not r["human_label"]]
    print(__doc__.split("You label")[1])
    for n, r in enumerate(todo, 1):
        p = out_path(r)
        text = p.read_text() if p.exists() else "(output file missing)"
        lines = text.splitlines()
        print("\n" + "=" * 70)
        print(f"Script {len(rows) - len(todo) + n} of {len(rows)}   (database: llm_{r['instance']})")
        print("-" * 70)
        print("\n".join(lines[:60]) if lines else "(empty output)")
        if len(lines) > 60:
            print(f"... ({len(lines) - 60} more lines not shown)")
        print("-" * 70)
        while True:
            a = input("Your reading: [f]ound, [c]lean, [u]nusable, [q]uit and save: ").strip().lower()
            if a in ("f", "c", "u", "q"):
                break
        if a == "q":
            break
        r["human_label"] = NAMES[a]
        write_sheet(rows)
    left = sum(1 for r in rows if not r["human_label"])
    print(f"\nSaved. {len(rows) - left} labelled, {left} left.")


def auto_label(s):
    if s["parseable"] == "0":
        return "UNUSABLE"
    return "CLEAN" if s["verdict_clean"] == "1" else "FOUND"


def cmd_agree():
    scores = {(s["model"], s["instance"], s["condition"], s["trial"]): s for s in load_scores()}
    rows = [r for r in read_sheet() if r["human_label"]]
    if not rows:
        sys.exit("No labels yet.")
    cats = ["FOUND", "CLEAN", "UNUSABLE"]
    table = {(h, a): 0 for h in cats for a in cats}
    for r in rows:
        a = auto_label(scores[(r["model"], r["instance"], r["condition"], r["trial"])])
        table[(r["human_label"], a)] += 1
    n = len(rows)
    agree = sum(table[(c, c)] for c in cats)
    po = agree / n
    pe = sum((sum(table[(c, x)] for x in cats) / n) * (sum(table[(x, c)] for x in cats) / n) for c in cats)
    kappa = (po - pe) / (1 - pe) if pe < 1 else 1.0
    print(f"labelled={n} agree={agree} agreement={po:.3f} cohens_kappa={kappa:.3f}")
    print("rows = your label, columns = automated verdict")
    print("          " + "  ".join(f"{c:>8s}" for c in cats))
    for h in cats:
        print(f"{h:>8s}  " + "  ".join(f"{table[(h, a)]:8d}" for a in cats))
    for r in rows:
        a = auto_label(scores[(r["model"], r["instance"], r["condition"], r["trial"])])
        if a != r["human_label"]:
            print(f"DISAGREE: {r['model']} {r['instance']} c{r['condition']} t{r['trial']}: you={r['human_label']} automated={a}")


if __name__ == "__main__":
    cmd = sys.argv[1] if len(sys.argv) > 1 else ""
    {"sample": cmd_sample, "label": cmd_label, "agree": cmd_agree}.get(cmd, lambda: print(__doc__))()
