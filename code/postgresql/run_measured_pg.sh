#!/bin/bash
# run_measured_pg.sh - measured PostgreSQL runs (slot residue and downstream sink).
# Usage (from the experiments folder; no password needed):
#   TRIALS=1 SCALES="1000" ./run_measured_pg.sh   smoke test
#   ./run_measured_pg.sh                          full run: 10 trials, scales 1000 and 100000
# Output: ../results/pm1_slot_residue.csv, ../results/pm2_sink.csv, ../results/measured_pg.log
TRIALS="${TRIALS:-10}"
SCALES="${SCALES:-1000 100000}"
RES="../results"
LOG="$RES/measured_pg.log"

for f in pm1_slot_residue pm2_sink; do
  docker cp "$f.sql" "dasfaa-pg:/tmp/$f.sql" > /dev/null || { echo "copy of $f.sql failed"; exit 1; }
done
for db in erasure_m_pg sink_m_pg; do
  docker exec dasfaa-pg psql -U postgres -Atc "SELECT 1 FROM pg_database WHERE datname='$db'" < /dev/null | grep -q 1 \
    || docker exec dasfaa-pg psql -U postgres -qc "CREATE DATABASE $db" < /dev/null
done

run_sql () {   # $1 = script, $2 = csv, rest = psql -v assignments
  local script="$1" csv="$2"; shift 2
  local vars=(); for a in "$@"; do vars+=(-v "$a"); done
  echo "=== $(date -u +%FT%TZ) $script $* ===" >> "$LOG"
  docker exec dasfaa-pg psql -U postgres -d postgres -q -At "${vars[@]}" -f "/tmp/$script.sql" < /dev/null 2>&1 \
    | tee -a "$LOG" | grep '^RESULT,' | sed 's/^RESULT,//' | tee -a "$csv"
}

[ -f "$RES/pm1_slot_residue.csv" ] || echo "scale,replica_identity,method,trial,seed,src_rows_readable,insert_records_readable,erase_records,erase_records_readable,subjects_readable,wal_held_bytes,max_slot_wal_keep_size,changes_consumed,readable_after_consume" > "$RES/pm1_slot_residue.csv"
[ -f "$RES/pm2_sink.csv" ] || echo "trial,sink_rows_initial,partA_erased_left_in_sink,partB_erased_left_in_source,partB_erased_left_in_sink,marker_arrived,subscription_enabled,apply_error_count,sync_error_count" > "$RES/pm2_sink.csv"

START=$(date +%s)
for scale in $SCALES; do
  for identity in default full; do
    for method in DELETE UPDATE; do
      for t in $(seq 1 "$TRIALS"); do
        echo "--- pm1 slot: scale=$scale identity=$identity method=$method trial=$t ($(date +%T))"
        run_sql pm1_slot_residue "$RES/pm1_slot_residue.csv" scale="$scale" identity="$identity" method="$method" trial="$t" seed="$((1000 + t))"
      done
    done
  done
done
for t in $(seq 1 "$TRIALS"); do
  echo "--- pm2 sink: trial=$t ($(date +%T))"
  run_sql pm2_sink "$RES/pm2_sink.csv" trial="$t"
done
echo "Finished in $(( ($(date +%s) - START) / 60 )) minutes."
