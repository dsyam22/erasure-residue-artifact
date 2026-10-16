# What Survives a DELETE? - replication package

Scripts, raw results, prompts and model-written scripts for the paper
"What Survives a DELETE? Measuring Erasure Residue in Change Data Capture and
Temporal Tables" (DASFAA 2027, Industrial Track). Engines: SQL Server 2022,
PostgreSQL 17 and MariaDB 11.4.

All data is synthetic. Addresses use the reserved `example.invalid` domain.

## Layout

| Folder | Contents |
|---|---|
| `code/sqlserver/` | Measured SQL Server runs: residue (m1), schema change (m2), restore (m3), cleanup timing (m4), downstream copy (m5), per-subject removal and access (m6), temporal retention (f5 single run, f6 five runs), and their drivers |
| `code/postgresql/` | Measured PostgreSQL runs: slot residue (pm1), downstream copy (pm2), slot access (pm3), and the driver |
| `code/mariadb/` | MariaDB history and binary-log residue and remedies (`run_mariadb.sh`) |
| `code/llm/` | LLM study: task databases, ground truth, harness, hand-label tool |
| `code/exploratory/` | Single-run scripts used to design the study; not used for reported numbers |
| `results/` | One CSV per scenario, logs, and `llm/` with prompts, every model response, the extracted scripts, their execution output and the scores |

## Requirements

- Docker. The study used `mcr.microsoft.com/mssql/server:2022-latest`
  (16.0.4295.3, CU27) and `postgres:17` (17.11), both as linux/amd64 images,
  and `mariadb:11.4` (11.4.13).
- Bash and Python 3 (standard library only).
- For the LLM study: Ollama with `gemma4:e4b`, and API keys for the hosted
  models in `DEEPSEEK_API_KEY`, `OPENAI_API_KEY`, `GEMINI_API_KEY` and
  `ANTHROPIC_API_KEY`. The paper's runs cost about US$11 in total.

## Setup

```bash
export MSSQL_SA_PASSWORD='<choose a strong password>'
docker run -d --name dasfaa-mssql --platform linux/amd64 -e ACCEPT_EULA=Y \
  -e MSSQL_SA_PASSWORD="$MSSQL_SA_PASSWORD" -e MSSQL_AGENT_ENABLED=true \
  mcr.microsoft.com/mssql/server:2022-latest
docker run -d --name dasfaa-pg -e POSTGRES_PASSWORD='<choose a password>' \
  postgres:17 -c wal_level=logical
docker run -d --name dasfaa-mariadb -e MARIADB_ROOT_PASSWORD='Lab-only-2027' \
  mariadb:11.4 --log-bin=mariadb-bin --binlog-format=ROW --server-id=1
```

The drivers expect a `results` folder next to the folder they are run from.

## Reproducing each result

| Paper | Command (run from the script's folder) | Output | Approx. time |
|---|---|---|---|
| Table 1, Sect. 4 (schema changes), Sect. 5.5 | `TRIALS=10 SCALES="1000 100000 1000000" ./run_measured.sh` | `m1_residue.csv`, `m2_drift.csv`, `m3_restore.csv` | 25 min |
| Sect. 4 (PostgreSQL), Sect. 5.3 (PostgreSQL) | `SCALES="1000 100000 1000000" ./run_measured_pg.sh` | `pm1_slot_residue.csv`, `pm2_sink.csv` | 15 min |
| Sect. 4 (MariaDB), Sect. 5.4 (MariaDB) | `./run_mariadb.sh` | `md1_mariadb.csv` | 2 min |
| Table 2, Sect. 5.3 (SQL Server) | `./run_overnight.sh` | `m4_cleanup.csv`, `m5_sink.csv` | 3.5 h |
| Sect. 5.2, first run | run `f5_setup.sql`, then `./f5_poll.sh` for at least 26 h on a machine that does not sleep | `f5_run1.csv` | 26 h |
| Sect. 5.2, five runs | `nohup caffeinate -dimsu ./f6_run.sh > ../results/f6_run.log 2>&1 < /dev/null &` | `f6_temporal.csv` | 26-32 h |
| Sect. 5.4 (SQL Server) | `./run_m6.sh` | `m6_remedies.csv` | 2 min |
| Sect. 5.4 (PostgreSQL access) | `psql -U postgres -d postgres -f pm3_access.sql` in the PostgreSQL container | `pm3_access.txt` | seconds |
| Table 3, Sect. 6 | see below | `llm/llm_scores.csv` | about 12 h in all |

LLM study:

```bash
# build the nine task databases (case i5 must then age for 24 hours)
sqlcmd ... -i llm_build_instances.sql
python3 llm_study.py truth
python3 llm_study.py run --provider ollama   --model gemma4:e4b      --trials 10
python3 llm_study.py run --provider deepseek --model deepseek-flash  --trials 10
python3 llm_study.py run --provider deepseek --model deepseek-v4-pro --trials 10
# discovery (4) and optional discovery (5); run case i5 separately inside its window (see below)
python3 llm_study.py run --provider deepseek --model deepseek-flash --trials 10 --conditions 4 --instances i1,i2,i3,i4,i6,i7,i8,i9
python3 llm_study.py run --provider deepseek --model deepseek-flash --trials 10 --conditions 5 --instances i1,i2,i3,i4,i6,i7,i8,i9
# reasoning mode on, stored under its own label
python3 llm_study.py run --provider deepseek --model deepseek-v4-pro --thinking --label deepseek-v4-pro-thinking --trials 5 --conditions 1,4 --instances i1,i2,i3,i4,i6,i7,i8,i9
# agentic condition (6): queries required, errors shown, one repair
python3 llm_study.py run --provider deepseek --model deepseek-flash --trials 5 --conditions 6 --instances i1,i2,i3,i4,i6,i7,i8,i9
# newer hosted models, lowest reasoning setting; GPT and Haiku do not accept a temperature
A=i5,i1,i2,i3,i4,i6,i7,i8,i9    # i5 only inside its window (see below)
python3 llm_study.py run --provider openai --model gpt-6.1-sol --extra '{"reasoning_effort":"low"}' --no-temperature --trials 5 --instances $A --conditions 1,2,4,5
python3 llm_study.py run --provider openai --model gpt-6.1-sol --extra '{"reasoning_effort":"low"}' --no-temperature --trials 3 --instances $A --conditions 6
python3 llm_study.py run --provider anthropic --model claude-haiku-5-5 --no-temperature --trials 10 --instances $A --conditions 1,2,4,5
python3 llm_study.py run --provider anthropic --model claude-haiku-5-5 --no-temperature --trials 5 --instances $A --conditions 6
python3 llm_study.py run --provider gemini --model gemini-3.1-pro-preview --extra '{"reasoning_effort":"low"}' --trials 5 --instances $A --conditions 1,2,4,5
python3 llm_study.py run --provider gemini --model gemini-3.1-pro-preview --extra '{"reasoning_effort":"low"}' --trials 3 --instances $A --conditions 6
# --price-in/--price-out/--max-cost cap spending per run (estimates; check the provider's billing)
# what the older models queried in condition 4
python3 llm_discovery_check.py
# optional discovery: scripts that queried versus those that did not
python3 llm_c5_check.py
# all models: did each script (c1), query (c4) or run of queries (c5) look at the catalog?
python3 llm_model_check.py
python3 llm_study.py baselines
python3 llm_study.py summary
```

Case i5 has a one-day temporal retention period. Its scripts and the baselines
were run between 25 and 45 minutes after the period expired, while the erased
row was hidden from temporal queries but still in the history table. That
window lasted from 32 minutes to over four hours in our runs. For the discovery
condition, `llm_rebuild_i5.sql` rebuilds case i5 alone and prints the window in
which to run its scripts.

## Notes

- Model-written scripts run under the read-only login `llm_reader`. Its
  password in `llm_build_instances.sql` is a lab default for a local container.
- SQL Server and PostgreSQL ran under x86-64 emulation on an Apple Silicon laptop. Absolute
  times will differ on other hardware.
- Model outputs are not deterministic (temperature 0.7, or the provider default
  for GPT and Haiku); rerunning gives different scripts, and hosted models change
  behind a fixed name. The scripts we scored (October 2026) are in
  `results/llm/raw/`.
- Gemini's trials 6-10 exist for some cases (run before its daily request quota
  stopped the first run); the paper reports trials 1-5 only.

## Human check of the automated scoring

`results/llm/label_sheet.csv` holds the first author's reading of 45 script outputs
(five per case, sampled with a fixed seed by `code/llm/llm_label.py sample`).
`python3 llm_label.py agree` compares them with the automated verdicts:
43 of 45 agree, Cohen's kappa 0.93. A second sheet,
`results/llm/label_sheet_discovery.csv` (27 scripts, three per case, from conditions 4 and 5;
`llm_label.py ... --discovery`), agrees 27 of 27.

## License

- **Code** (everything under `code/`): MIT License, see `LICENSE`.
- **Results and other data** (everything under `results/`, including prompts,
  model-written scripts and the label sheet): Creative Commons Attribution 4.0
  International (CC BY 4.0), https://creativecommons.org/licenses/by/4.0/

All data in this package is synthetic. If you use the package, please cite the
paper "What Survives a DELETE? Measuring Erasure Residue in Change Data Capture
and Temporal Tables" (Syam Sajit Dondapati and Varunbabu Suddapalli).
