#!/usr/bin/env python3
"""llm_study.py - LLM erasure-verification study (RQ3). Standard library only.

Run from the experiments/llm folder. MSSQL_SA_PASSWORD must be exported (used for the
configuration dumps and for ground truth). Model-written scripts run as the read-only
login llm_reader, so they cannot change any data.

  python3 llm_study.py truth                       show ground truth for the nine instances
  python3 llm_study.py prompt i3 2                 print one prompt (instance, condition)
  python3 llm_study.py baselines                   score the naive and full-checklist baselines
  python3 llm_study.py run --provider ollama --model gemma4:e4b --trials 10
  python3 llm_study.py run --provider deepseek --model <model id> --trials 3 --max-tokens 400000
  python3 llm_study.py run --provider deepseek --model <model id> --trials 10 --conditions 4
                                                   condition 4 = discovery: the model first runs one
                                                   catalog query of its own, then writes the script
                                                   condition 5 = iterative discovery: up to three
                                                   queries before the script
                                                   condition 6 = agentic: at least one and up to three
                                                   queries, errors shown, one repair of the script
  python3 llm_study.py run --provider deepseek --model deepseek-v4-pro --thinking --label deepseek-v4-pro-thinking ...
                                                   reasoning mode on, stored under its own label
  python3 llm_study.py summary                     aggregate results/llm/llm_scores.csv

Outputs go to ../../results/llm/ : raw responses, extracted scripts, execution output,
and llm_scores.csv (one row per scored script).
"""
import argparse, csv, json, os, re, subprocess, sys, time, urllib.error, urllib.request
from pathlib import Path

CONTAINER = "dasfaa-mssql"
SQLCMD = "/opt/mssql-tools18/bin/sqlcmd"
READER_USER, READER_PW = "llm_reader", "Reader#2026-lab"
RES = Path(__file__).resolve().parent.parent.parent / "results" / "llm"
HERE = Path(__file__).resolve().parent
TEMPERATURE = 0.7

SUBJECT = ("customer_id 42, full_name 'Subject_0000042', email 'subject42@example.invalid', "
           "phone '+1-555-0000042'")
ERASED_ROWS = "The rows for this person were deleted with DELETE statements"
INSTANCES = {
    "i1": dict(field="email", value="subject42@example.invalid",
               erasure=ERASED_ROWS + " from dbo.customer."),
    "i2": dict(field="email", value="subject42@example.invalid",
               erasure=ERASED_ROWS + " from dbo.customer."),
    "i3": dict(field="email", value="subject42@example.invalid",
               erasure=ERASED_ROWS + " from dbo.customer and dbo.member (member_id 42)."),
    "i4": dict(field="email", value="subject42@example.invalid",
               erasure="The rows for this person in dbo.customer and dbo.member (member_id 42) were "
                       "anonymized in place with UPDATE statements: full_name set to 'REDACTED', email "
                       "to 'redacted@example.invalid', phone to NULL."),
    "i5": dict(field="email", value="subject42@example.invalid",
               erasure=ERASED_ROWS + " from dbo.customer."),
    "i6": dict(field="phone", value="+1-555-0000042",
               erasure="The company erased all customers' phone numbers by dropping the phone column "
                       "from dbo.customer. Only the phone number is in scope: verify that this person's "
                       "phone number is no longer stored anywhere. Name and email are legitimately kept."),
    "i7": dict(field="email", value="subject42@example.invalid",
               erasure=ERASED_ROWS + " from dbo.customer."),
    "i8": dict(field="email", value="subject42@example.invalid",
               erasure=ERASED_ROWS + " from dbo.customer."),
    "i9": dict(field="email", value="subject42@example.invalid",
               erasure=ERASED_ROWS + " from dbo.customer."),
}
HINT = ("Hint: consider change-tracking features (CDC change tables, temporal history tables) "
        "and downstream copies of the data.")

Q_SCHEMA = """SET NOCOUNT ON;
SELECT s.name + '.' + t.name + ' (' +
       STRING_AGG(c.name + ' ' + ty.name, ', ') WITHIN GROUP (ORDER BY c.column_id) + ')'
FROM sys.tables t JOIN sys.schemas s ON s.schema_id = t.schema_id
JOIN sys.columns c ON c.object_id = t.object_id
JOIN sys.types ty ON ty.user_type_id = c.user_type_id
WHERE s.name <> 'cdc' AND t.temporal_type <> 1 AND t.is_ms_shipped = 0
GROUP BY s.name, t.name ORDER BY 1;"""
Q_CONFIG = """SET NOCOUNT ON;
SELECT 'database: cdc_enabled=' + CAST(is_cdc_enabled AS VARCHAR(1)) FROM sys.databases WHERE name = DB_NAME();
SELECT 'table: ' + s.name + '.' + t.name + ', temporal_type=' + t.temporal_type_desc COLLATE DATABASE_DEFAULT
     + ISNULL(', history_table=' + hs.name + '.' + h.name, '')
     + CASE WHEN t.temporal_type = 2 THEN ', history_retention=' +
            CASE WHEN t.history_retention_period = -1 THEN 'INFINITE'
                 ELSE CAST(t.history_retention_period AS VARCHAR(10)) + ' ' + t.history_retention_period_unit_desc COLLATE DATABASE_DEFAULT END
            ELSE '' END
FROM sys.tables t JOIN sys.schemas s ON s.schema_id = t.schema_id
LEFT JOIN sys.tables h ON h.object_id = t.history_table_id
LEFT JOIN sys.schemas hs ON hs.schema_id = h.schema_id
WHERE NOT (s.name = 'cdc' AND t.name NOT LIKE '%[_]CT') AND t.name <> 'systranschemas'
ORDER BY 1;
IF OBJECT_ID('cdc.change_tables') IS NOT NULL
    SELECT 'cdc capture instance: ' + ct.capture_instance + ', source=' + OBJECT_SCHEMA_NAME(ct.source_object_id)
         + '.' + OBJECT_NAME(ct.source_object_id) + ', captured_columns=' +
           (SELECT STRING_AGG(cc.column_name, ',') FROM cdc.captured_columns cc WHERE cc.object_id = ct.object_id)
    FROM cdc.change_tables ct;"""

# Naive baseline: the source table(s), plus a time-travel query when the table is temporal.
Q_NAIVE = """SET NOCOUNT ON;
DECLARE @sql NVARCHAR(MAX) = N'';
SELECT @sql = @sql + N'SELECT ''' + s.name + N'.' + t.name + N''' AS object_name, COUNT(*) AS rows_found FROM '
            + QUOTENAME(s.name) + N'.' + QUOTENAME(t.name)
            + CASE WHEN t.temporal_type = 2 THEN N' FOR SYSTEM_TIME ALL' ELSE N'' END
            + N' WHERE ' + QUOTENAME(c.name) + N' = @v UNION ALL '
FROM sys.tables t JOIN sys.schemas s ON s.schema_id = t.schema_id
JOIN sys.columns c ON c.object_id = t.object_id
WHERE s.name = 'dbo' AND t.temporal_type <> 1 AND t.is_ms_shipped = 0 AND c.name = '$(FIELD)';
IF LEN(@sql) > 0
BEGIN
    SET @sql = LEFT(@sql, LEN(@sql) - 10);
    EXEC sp_executesql @sql, N'@v NVARCHAR(200)', @v = N'$(VALUE)';
END
ELSE
    SELECT 'dbo.customer' AS object_name, 0 AS rows_found;"""


def die(msg):
    print(msg, file=sys.stderr)
    sys.exit(1)


def sqlcmd(db, sql_text, user="sa", password=None, variables=None, timeout=120, headers=False):
    """Run a script inside the container; return its output as text."""
    if user == "sa":
        password = os.environ.get("MSSQL_SA_PASSWORD") or die("MSSQL_SA_PASSWORD is not set in this window.")
    RES.mkdir(parents=True, exist_ok=True)
    local = RES / f"_tmp_{os.getpid()}.sql"
    local.write_text(sql_text)
    remote = f"/tmp/llm_{os.getpid()}.sql"
    subprocess.run(["docker", "cp", str(local), f"{CONTAINER}:{remote}"], check=True,
                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    cmd = ["docker", "exec", CONTAINER, SQLCMD, "-S", "localhost", "-U", user, "-P", password, "-C",
           "-d", db, "-W", "-s", "|", "-t", "60", "-i", remote]
    if not headers:
        cmd += ["-h", "-1"]
    for k, v in (variables or {}).items():
        cmd += ["-v", f"{k}={v}"]
    try:
        p = subprocess.run(cmd, stdin=subprocess.DEVNULL, capture_output=True, text=True, timeout=timeout)
        out = p.stdout + p.stderr
    except subprocess.TimeoutExpired:
        out = "Sqlcmd: Error: harness timeout"
    finally:
        local.unlink(missing_ok=True)
    return out


ROW = re.compile(r"^\s*([\[\]\w.$ ]+?)\s*\|\s*(-?\d+)\s*$")


def norm_object(name):
    name = name.replace("[", "").replace("]", "").strip().lower()
    parts = [p.strip() for p in name.split(".") if p.strip()]
    if len(parts) >= 3:
        parts = parts[-2:]
    if len(parts) == 1:
        parts = ["dbo", parts[0]]
    return ".".join(parts)


def parse_rows(output):
    """object_name|rows_found lines -> {object: max count seen}."""
    found = {}
    for line in output.splitlines():
        m = ROW.match(line)
        if m:
            obj = norm_object(m.group(1))
            found[obj] = max(found.get(obj, 0), int(m.group(2)))
    return found


def has_error(output):
    return bool(re.search(r"^Msg \d+, Level (1[1-9]|2\d)|Sqlcmd: Error", output, re.M))


def truth(inst):
    spec = INSTANCES[inst]
    out = sqlcmd(f"llm_{inst}", (HERE / "llm_truth.sql").read_text(),
                 variables={"FIELD": spec["field"], "VALUE": spec["value"]})
    return {o: n for o, n in parse_rows(out).items() if n > 0}


def score(inst, output, truth_pos):
    """Compare what a script reported with the ground truth for the instance."""
    found = parse_rows(output)
    flagged = {o for o, n in found.items() if n > 0}
    truth_objs = set(truth_pos)
    hits = set()
    for t in truth_objs:
        if t in flagged:
            hits.add(t)
        elif t.endswith("_history"):
            base = t[: -len("_history")]
            # a time-travel query reports the history copy under the base table's name
            if base in flagged and base not in truth_objs:
                hits.add(t)
    credited = {t[: -len("_history")] for t in hits if t.endswith("_history")}
    false_pos = flagged - truth_objs - credited
    parseable = len(found) > 0
    truth_clean = len(truth_objs) == 0
    verdict_clean = parseable and not flagged
    return dict(
        executes=int(not has_error(output)), parseable=int(parseable),
        truth_surfaces=len(truth_objs), surfaces_found=len(hits),
        recall="" if truth_clean else round(len(hits) / len(truth_objs), 3),
        false_positives=len(false_pos),
        verdict_clean=int(verdict_clean), truth_clean=int(truth_clean),
        false_clean=int(parseable and verdict_clean and not truth_clean),
        false_alarm=int(parseable and truth_clean and bool(flagged)),
        objects_checked=len(found))


TASK = (
    "Task: write one T-SQL script that verifies whether the erased personal data is still stored "
    "anywhere in this database.\nRequirements:\n"
    "- Read-only: SELECT statements only (temporary tables and variables are allowed).\n"
    "- The script must return exactly one result set with two columns: object_name (the "
    "schema.table of each place you checked) and rows_found (the number of rows there that still "
    "contain the subject's original personal data in scope).\n"
    "- Include one row for every object you checked, with 0 where nothing was found.\n"
    "- Do not return any other result sets and do not print messages.\n"
    "Reply with the script only, inside one ```sql code block.")
# Condition 4 (discovery). Step 1 gives the same information as condition 1 and lets the model
# run one query of its own; step 2 returns that query's output and asks for the script. The
# wording does not name any change-tracking feature.
DISCOVER = (
    "You will be asked to write a T-SQL script that verifies whether the erased personal data is "
    "still stored anywhere in this database. Before that, you may inspect the database once.\n"
    "Reply with one read-only T-SQL batch (SELECT statements only) that returns whatever you want "
    "to know about this database, for example from its catalog views. Its output will be given "
    "back to you. Reply with the query only, inside one ```sql code block.")
MAX_QUERIES = 3               # condition 5
ITERATE = (
    "You will be asked to write a T-SQL script that verifies whether the erased personal data is "
    "still stored anywhere in this database. Before that, you may inspect the database with up to "
    "three read-only T-SQL batches (SELECT statements only), one at a time; each batch's output "
    "will be given back to you.\n"
    "To run a batch, reply with one ```sql code block whose first line is -- QUERY\n"
    "When you are ready, reply with the final script in one ```sql code block whose first line is "
    "-- SCRIPT, following the requirements below.\n\n")
AGENT = (
    "You will be asked to write a T-SQL script that verifies whether the erased personal data is "
    "still stored anywhere in this database. First inspect the database with between one and three "
    "read-only T-SQL batches (SELECT statements only), one at a time; each batch's output, including "
    "any error message, will be given back to you. Your final script will then be run and, if it "
    "fails, you will see the error and may repair it once.\n"
    "To run a batch, reply with one ```sql code block whose first line is -- QUERY\n"
    "When you are ready, reply with the final script in one ```sql code block whose first line is "
    "-- SCRIPT, following the requirements below.\n\n")
DISCOVERY_OUTPUT_CAP = 5000   # characters of query output returned to the model
SYSTEM = "You are a senior SQL Server database engineer."


def build_prompt(inst, cond):
    db, spec = f"llm_{inst}", INSTANCES[inst]
    schema = "\n".join(l for l in sqlcmd(db, Q_SCHEMA).splitlines() if l.strip())
    parts = [f"Database: {db} on Microsoft SQL Server 2022.",
             f"The data subject's original personal data: {SUBJECT}.",
             f"Erasure that was performed: {spec['erasure']}",
             "Tables (schema.table and columns):\n" + schema]
    if has_error(schema):
        die(f"Schema query failed for {db}:\n{schema}")
    if cond == 4:
        parts.append(DISCOVER)
        return "\n\n".join(parts)
    if cond == 5:
        parts.append(ITERATE + TASK)
        return "\n\n".join(parts)
    if cond == 6:
        parts.append(AGENT + TASK)
        return "\n\n".join(parts)
    if cond >= 2:
        config = "\n".join(l for l in sqlcmd(db, Q_CONFIG).splitlines() if l.strip())
        if has_error(config):
            die(f"Configuration query failed for {db}:\n{config}")
        parts.append("Database configuration:\n" + config)
    if cond >= 3:
        parts.append(HINT)
    parts.append(TASK)
    return "\n\n".join(parts)


def extract_sql(text):
    m = re.search(r"```(?:sql|tsql|t-sql)?\s*\n(.*?)```", text, re.S | re.I)
    return (m.group(1) if m else text).strip() + "\n"


def call_ollama(model, messages):
    body = json.dumps({"model": model, "stream": False,
                       "messages": messages,
                       "options": {"temperature": TEMPERATURE, "num_ctx": 8192}}).encode()
    req = urllib.request.Request("http://localhost:11434/api/chat", data=body,
                                 headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=900) as r:
        d = json.load(r)
    return d["message"]["content"], d.get("prompt_eval_count", 0), d.get("eval_count", 0)


THINKING = False
EXTRA = {}            # extra request-body fields from --extra (e.g. a reasoning-effort setting)
SEND_TEMPERATURE = True
ENDPOINTS = {
    "openai": ("https://api.openai.com/v1/chat/completions", "OPENAI_API_KEY"),
    "gemini": ("https://generativelanguage.googleapis.com/v1beta/openai/chat/completions", "GEMINI_API_KEY"),
}


def call_openai_compat(provider, model, messages):
    url, key_env = ENDPOINTS[provider]
    key = os.environ.get(key_env) or die(f"{key_env} is not set in this window.")
    body = {"model": model, "messages": messages}
    if SEND_TEMPERATURE:
        body["temperature"] = TEMPERATURE
    body.update(EXTRA)
    req = urllib.request.Request(url, data=json.dumps(body).encode(),
                                 headers={"Content-Type": "application/json", "Authorization": f"Bearer {key}"})
    try:
        with urllib.request.urlopen(req, timeout=900) as r:
            d = json.load(r)
    except urllib.error.HTTPError as e:
        raise RuntimeError(f"HTTP {e.code}: {e.read().decode(errors='replace')[:600]}")
    u = d.get("usage", {})
    return (d["choices"][0]["message"].get("content") or ""), u.get("prompt_tokens", 0), u.get("completion_tokens", 0)


def call_anthropic(model, messages):
    key = os.environ.get("ANTHROPIC_API_KEY") or die("ANTHROPIC_API_KEY is not set in this window.")
    system = "\n".join(m["content"] for m in messages if m["role"] == "system")
    msgs = [m for m in messages if m["role"] != "system"]
    body = {"model": model, "max_tokens": 16000, "system": system, "messages": msgs}
    if SEND_TEMPERATURE:
        body["temperature"] = TEMPERATURE
    body.update(EXTRA)
    req = urllib.request.Request("https://api.anthropic.com/v1/messages", data=json.dumps(body).encode(),
                                 headers={"Content-Type": "application/json", "x-api-key": key,
                                          "anthropic-version": "2023-06-01"})
    try:
        with urllib.request.urlopen(req, timeout=900) as r:
            d = json.load(r)
    except urllib.error.HTTPError as e:
        raise RuntimeError(f"HTTP {e.code}: {e.read().decode(errors='replace')[:600]}")
    text = "".join(b.get("text", "") for b in d.get("content", []) if b.get("type") == "text")
    u = d.get("usage", {})
    return text, u.get("input_tokens", 0), u.get("output_tokens", 0)


def call_deepseek(model, messages):
    key = os.environ.get("DEEPSEEK_API_KEY") or die("DEEPSEEK_API_KEY is not set in this window.")
    body = json.dumps({"model": model, "stream": False, "temperature": TEMPERATURE,
                       "thinking": {"type": "enabled" if THINKING else "disabled"},
                       "messages": messages}).encode()
    req = urllib.request.Request("https://api.deepseek.com/chat/completions", data=body,
                                 headers={"Content-Type": "application/json", "Authorization": f"Bearer {key}"})
    with urllib.request.urlopen(req, timeout=900) as r:
        d = json.load(r)
    u = d.get("usage", {})
    return d["choices"][0]["message"]["content"], u.get("prompt_tokens", 0), u.get("completion_tokens", 0)


FIELDS = ["model", "instance", "condition", "trial", "executes", "parseable", "truth_surfaces",
          "surfaces_found", "recall", "false_positives", "verdict_clean", "truth_clean", "false_clean",
          "false_alarm", "objects_checked", "prompt_tokens", "completion_tokens", "scored_at_utc"]


def append_score(row):
    RES.mkdir(parents=True, exist_ok=True)
    path = RES / "llm_scores.csv"
    new = not path.exists()
    with path.open("a", newline="") as f:
        w = csv.DictWriter(f, fieldnames=FIELDS)
        if new:
            w.writeheader()
        w.writerow({k: row.get(k, "") for k in FIELDS})


def cmd_truth(_):
    for inst in INSTANCES:
        t = truth(inst)
        print(f"{inst}: {'CLEAN' if not t else ', '.join(f'{o}={n}' for o, n in sorted(t.items()))}")


def cmd_prompt(a):
    print(build_prompt(a.instance, a.condition))


def cmd_baselines(_):
    for inst, spec in INSTANCES.items():
        t = truth(inst)
        variables = {"FIELD": spec["field"], "VALUE": spec["value"]}
        for name, sql_text in (("baseline_naive", Q_NAIVE), ("baseline_full", (HERE / "llm_truth.sql").read_text())):
            out = sqlcmd(f"llm_{inst}", sql_text, user=READER_USER, password=READER_PW, variables=variables)
            s = score(inst, out, t)
            append_score(dict(s, model=name, instance=inst, condition=0, trial=1,
                              scored_at_utc=time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())))
            print(f"{name:15s} {inst}: executes={s['executes']} recall={s['recall']} "
                  f"false_clean={s['false_clean']} false_alarm={s['false_alarm']}")


def run_query(inst, sql_text):
    out = sqlcmd(f"llm_{inst}", sql_text, user=READER_USER, password=READER_PW, headers=True)
    out = "\n".join(l.rstrip() for l in out.splitlines() if l.strip())
    if len(out) > DISCOVERY_OUTPUT_CAP:
        out = out[:DISCOVERY_OUTPUT_CAP] + "\n[output truncated]"
    return out or "(no output)"


def cmd_run(a):
    global THINKING, EXTRA, SEND_TEMPERATURE
    THINKING = a.thinking
    EXTRA = json.loads(a.extra) if a.extra else {}
    SEND_TEMPERATURE = not a.no_temperature
    if a.provider == "ollama":
        call = call_ollama
    elif a.provider == "deepseek":
        call = call_deepseek
    elif a.provider == "anthropic":
        call = call_anthropic
    else:
        call = lambda model, msgs, _p=a.provider: call_openai_compat(_p, model, msgs)
    a.label = a.label or a.model
    tag = re.sub(r"[^\w.-]", "_", a.label)
    raw_dir = RES / "raw" / tag
    raw_dir.mkdir(parents=True, exist_ok=True)
    insts = a.instances.split(",") if a.instances else list(INSTANCES)
    conds = [int(c) for c in a.conditions.split(",")]
    # Refuse to start if another run for this model is already going: two runs would score
    # the same trials twice.
    lock = raw_dir / "run.lock"
    if lock.exists():
        try:
            other = int(lock.read_text().strip())
            os.kill(other, 0)
            die(f"Another run for {a.label} is already in progress (process {other}). Not starting a second one.")
        except (ValueError, ProcessLookupError):
            pass                                  # stale lock from a run that has ended
    lock.write_text(str(os.getpid()))
    try:
        _run_trials(a, call, raw_dir, insts, conds)
    finally:
        lock.unlink(missing_ok=True)


def _run_trials(a, call, raw_dir, insts, conds):
    prompts = {(i, c): build_prompt(i, c) for i in insts for c in conds}
    prompt_dir = RES / "prompts"
    prompt_dir.mkdir(parents=True, exist_ok=True)
    for (i, c), text in prompts.items():
        (prompt_dir / f"{i}_c{c}.txt").write_text(text)
    total_tokens, calls, spent_in, spent_out = 0, 0, 0, 0
    for inst in insts:
        for cond in conds:
            for trial in range(1, a.trials + 1):
                stem = raw_dir / f"{inst}_c{cond}_t{trial}"
                if stem.with_suffix(".txt").exists():
                    continue
                cost = (spent_in * a.price_in + spent_out * a.price_out) / 1e6
                if a.max_cost and cost >= a.max_cost:
                    print(f"Cost cap of ${a.max_cost} reached (${cost:.2f} spent) after {calls} calls; stopping.")
                    return
                if a.max_tokens and total_tokens >= a.max_tokens:
                    print(f"Token cap of {a.max_tokens} reached after {calls} calls; stopping.")
                    return
                msgs = [{"role": "system", "content": SYSTEM},
                        {"role": "user", "content": prompts[(inst, cond)]}]
                try:
                    text, ptok, ctok = call(a.model, msgs)
                    calls += 1
                    if cond == 4:
                        # discovery: run the model's own query, hand back its output, ask for the script
                        q_sql = extract_sql(text)
                        q_out = sqlcmd(f"llm_{inst}", q_sql, user=READER_USER, password=READER_PW, headers=True)
                        q_out = "\n".join(l.rstrip() for l in q_out.splitlines() if l.strip())
                        if len(q_out) > DISCOVERY_OUTPUT_CAP:
                            q_out = q_out[:DISCOVERY_OUTPUT_CAP] + "\n[output truncated]"
                        Path(str(stem) + "_q.sql").write_text(q_sql)
                        Path(str(stem) + "_q.out").write_text(q_out)
                        msgs += [{"role": "assistant", "content": text},
                                 {"role": "user", "content": "Output of your query:\n" + (q_out or "(no output)")
                                                             + "\n\n" + TASK}]
                        text, p2, c2 = call(a.model, msgs)
                        calls += 1
                        ptok, ctok = ptok + p2, ctok + c2
                    elif cond == 6:
                        nq = 0
                        while True:
                            is_query = extract_sql(text).lstrip().upper().startswith("-- QUERY")
                            if not is_query and nq >= 1:
                                break
                            if not is_query:      # a script before any query: ask for a query first
                                note = "Run at least one query before writing the script."
                                msgs += [{"role": "assistant", "content": text}, {"role": "user", "content": note}]
                            elif nq >= MAX_QUERIES:
                                msgs += [{"role": "assistant", "content": text},
                                         {"role": "user", "content": "No more queries are allowed. Reply now with "
                                                                     "the final script (first line -- SCRIPT).\n\n" + TASK}]
                            else:
                                nq += 1
                                q_sql = extract_sql(text)
                                q_out = run_query(inst, q_sql)
                                Path(f"{stem}_q{nq}.sql").write_text(q_sql)
                                Path(f"{stem}_q{nq}.out").write_text(q_out)
                                msgs += [{"role": "assistant", "content": text},
                                         {"role": "user", "content": f"Output of query {nq}:\n{q_out}\n\n"
                                                                     f"Queries left: {MAX_QUERIES - nq}."}]
                            text, p2, c2 = call(a.model, msgs)
                            calls += 1
                            ptok, ctok = ptok + p2, ctok + c2
                            if calls > 200000 or len(msgs) > 14:
                                break
                        # run the script once; on error or unusable output, show it and allow one repair
                        first = sqlcmd(f"llm_{inst}", extract_sql(text), user=READER_USER, password=READER_PW)
                        if has_error(first) or not parse_rows(first):
                            Path(f"{stem}_first.sql").write_text(extract_sql(text))
                            Path(f"{stem}_first.out").write_text(first)
                            msgs += [{"role": "assistant", "content": text},
                                     {"role": "user", "content": "Your script produced this output:\n"
                                      + (first[:DISCOVERY_OUTPUT_CAP] or "(no output)")
                                      + "\n\nRepair it once. Reply with the final script only (first line -- SCRIPT)."}]
                            text, p2, c2 = call(a.model, msgs)
                            calls += 1
                            ptok, ctok = ptok + p2, ctok + c2
                    elif cond == 5:
                        # iterative discovery: run each "-- QUERY" batch and return its output,
                        # at most MAX_QUERIES times, then insist on the final script
                        nq = 0
                        while extract_sql(text).lstrip().upper().startswith("-- QUERY"):
                            if nq >= MAX_QUERIES:
                                msgs += [{"role": "assistant", "content": text},
                                         {"role": "user", "content": "No more queries are allowed. Reply now with "
                                                                     "the final script (first line -- SCRIPT).\n\n" + TASK}]
                            else:
                                nq += 1
                                q_sql = extract_sql(text)
                                q_out = run_query(inst, q_sql)
                                Path(f"{stem}_q{nq}.sql").write_text(q_sql)
                                Path(f"{stem}_q{nq}.out").write_text(q_out)
                                msgs += [{"role": "assistant", "content": text},
                                         {"role": "user", "content": f"Output of query {nq}:\n{q_out}\n\n"
                                                                     f"Queries left: {MAX_QUERIES - nq}."}]
                            text, p2, c2 = call(a.model, msgs)
                            calls += 1
                            ptok, ctok = ptok + p2, ctok + c2
                            if nq >= MAX_QUERIES and extract_sql(text).lstrip().upper().startswith("-- QUERY"):
                                break   # asked twice for the script and still got a query: score as is
                except Exception as e:          # network or API error: report and move on
                    print(f"{inst} c{cond} t{trial}: call failed: {e}")
                    continue
                total_tokens += ptok + ctok
                spent_in, spent_out = spent_in + ptok, spent_out + ctok
                sql_text = extract_sql(text)
                stem.with_suffix(".txt").write_text(text)
                stem.with_suffix(".sql").write_text(sql_text)
                out = sqlcmd(f"llm_{inst}", sql_text, user=READER_USER, password=READER_PW)
                stem.with_suffix(".out").write_text(out)
                s = score(inst, out, truth(inst))
                append_score(dict(s, model=a.label, instance=inst, condition=cond, trial=trial,
                                  prompt_tokens=ptok, completion_tokens=ctok,
                                  scored_at_utc=time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())))
                print(f"{inst} c{cond} t{trial}: executes={s['executes']} parseable={s['parseable']} "
                      f"recall={s['recall']} false_clean={s['false_clean']} false_alarm={s['false_alarm']} "
                      f"tokens={ptok}+{ctok} (total {total_tokens})", flush=True)
    print(f"Done: {calls} calls, {total_tokens} tokens ({spent_in} in, {spent_out} out), "
          f"estimated cost ${(spent_in * a.price_in + spent_out * a.price_out) / 1e6:.2f}.")


def cmd_summary(_):
    path = RES / "llm_scores.csv"
    if not path.exists():
        die("No llm_scores.csv yet.")
    rows = list(csv.DictReader(path.open()))
    groups = {}
    for r in rows:
        groups.setdefault((r["model"], r["condition"]), []).append(r)
    print("model,condition,scripts,executes,parseable,false_clean_of_residue_cases,false_clean_of_residue_cases_that_ran,mean_recall,false_alarm_of_clean_cases,tokens")
    for (model, cond), g in sorted(groups.items()):
        res = [r for r in g if r["truth_clean"] == "0"]
        ran_res = [r for r in res if r["executes"] == "1"]
        cln = [r for r in g if r["truth_clean"] == "1"]
        rec = [float(r["recall"]) for r in res if r["recall"] != ""]
        tok = sum(int(r["prompt_tokens"] or 0) + int(r["completion_tokens"] or 0) for r in g)
        print(",".join(str(x) for x in [
            model, cond, len(g), sum(int(r["executes"]) for r in g), sum(int(r["parseable"]) for r in g),
            f"{sum(int(r['false_clean']) for r in res)}/{len(res)}",
            f"{sum(int(r['false_clean']) for r in ran_res)}/{len(ran_res)}",
            round(sum(rec) / len(rec), 3) if rec else "",
            f"{sum(int(r['false_alarm']) for r in cln)}/{len(cln)}", tok]))


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest="cmd", required=True)
    sub.add_parser("truth").set_defaults(fn=cmd_truth)
    p = sub.add_parser("prompt"); p.add_argument("instance"); p.add_argument("condition", type=int)
    p.set_defaults(fn=cmd_prompt)
    sub.add_parser("baselines").set_defaults(fn=cmd_baselines)
    r = sub.add_parser("run")
    r.add_argument("--provider", choices=["ollama", "deepseek", "openai", "gemini", "anthropic"], required=True)
    r.add_argument("--model", required=True)
    r.add_argument("--trials", type=int, default=3)
    r.add_argument("--instances", default="")
    r.add_argument("--conditions", default="1,2,3")
    r.add_argument("--max-tokens", type=int, default=0, help="stop once this many total tokens are used")
    r.add_argument("--thinking", action="store_true", help="DeepSeek only: reasoning mode on")
    r.add_argument("--label", default="", help="name to store results under (default: the model id)")
    r.add_argument("--extra", default="", help='JSON merged into the request body, e.g. \'{"reasoning_effort":"low"}\'')
    r.add_argument("--no-temperature", action="store_true", help="do not send a temperature (for models that reject it)")
    r.add_argument("--price-in", type=float, default=0.0, help="US$ per 1M input tokens, for the cost cap")
    r.add_argument("--price-out", type=float, default=0.0, help="US$ per 1M output tokens, for the cost cap")
    r.add_argument("--max-cost", type=float, default=0.0, help="stop once the estimated cost reaches this many US$")
    r.set_defaults(fn=cmd_run)
    sub.add_parser("summary").set_defaults(fn=cmd_summary)
    a = ap.parse_args()
    a.fn(a)


if __name__ == "__main__":
    main()
