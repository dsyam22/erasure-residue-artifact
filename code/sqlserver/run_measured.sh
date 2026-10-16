#!/bin/bash
# run_measured.sh - measured SQL Server runs for F1 to F4 and F8.
# Usage (from the experiments folder, with MSSQL_SA_PASSWORD exported):
#   ./run_measured.sh                          full run: 5 trials, scales 1000 and 100000
#   TRIALS=1 SCALES="1000" ./run_measured.sh   quick smoke test
#   ONLY=m1 SCALES="1000000" ./run_measured.sh  residue scenario only, at one scale
# Output: ../results/m1_residue.csv, m2_drift.csv, m3_restore.csv, and measured_sqlserver.log
TRIALS="${TRIALS:-5}"
ONLY="${ONLY:-all}"     # all, or one of: m1 m2 m3
SCALES="${SCALES:-1000 100000}"
RES="../results"
LOG="$RES/measured_sqlserver.log"

if [ -z "$MSSQL_SA_PASSWORD" ]; then echo "MSSQL_SA_PASSWORD is not set in this window. Stopping."; exit 1; fi
for f in m1_residue m2_drift m3_restore; do
  docker cp "$f.sql" "dasfaa-mssql:/tmp/$f.sql" > /dev/null || { echo "copy of $f.sql failed"; exit 1; }
done

run_sql () {   # $1 = script name, $2 = csv file, rest = sqlcmd variables
  local script="$1" csv="$2"; shift 2
  echo "=== $(date -u +%FT%TZ) $script $* ===" >> "$LOG"
  docker exec dasfaa-mssql /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "$MSSQL_SA_PASSWORD" \
      -C -W -h -1 -i "/tmp/$script.sql" -v "$@" < /dev/null 2>&1 | tee -a "$LOG" \
      | grep '^RESULT,' | sed 's/^RESULT,//' | tee -a "$csv"
}

[ -f "$RES/m1_residue.csv" ] || echo "scale,method,trial,seed,load_captured_rows,erase_records_captured,src_rows_readable,ct_copies,ct_subjects,hist_copies,hist_subjects,timetravel_subjects,cdc_retention_min,temporal_retention,load_capture_wait_s,erase_capture_wait_s" > "$RES/m1_residue.csv"
[ -f "$RES/m2_drift.csv" ]   || echo "trial,marker_captured,added_col_captured,updates_made,updates_recorded,dropped_col_in_source,dropped_col_still_captured,dropped_values_readable" > "$RES/m2_drift.csv"
[ -f "$RES/m3_restore.csv" ] || echo "trial,sequence,subject_present,is_cdc_enabled,change_table_exists,change_rows_subject,cdc_jobs,temporal_retention_enabled" > "$RES/m3_restore.csv"

START=$(date +%s)
if [ "$ONLY" = all ] || [ "$ONLY" = m1 ]; then
for scale in $SCALES; do
  for method in DELETE UPDATE; do
    for t in $(seq 1 "$TRIALS"); do
      echo "--- m1 residue: scale=$scale method=$method trial=$t ($(date +%T))"
      run_sql m1_residue "$RES/m1_residue.csv" SCALE="$scale" METHOD="$method" TRIAL="$t" SEED="$((1000 + t))"
    done
  done
done
fi
if [ "$ONLY" = all ] || [ "$ONLY" = m2 ]; then
for t in $(seq 1 "$TRIALS"); do
  echo "--- m2 drift: trial=$t ($(date +%T))"
  run_sql m2_drift "$RES/m2_drift.csv" TRIAL="$t"
done
fi
if [ "$ONLY" = all ] || [ "$ONLY" = m3 ]; then
for t in $(seq 1 "$TRIALS"); do
  echo "--- m3 restore: trial=$t ($(date +%T))"
  run_sql m3_restore "$RES/m3_restore.csv" TRIAL="$t"
done
fi
echo "Finished in $(( ($(date +%s) - START) / 60 )) minutes."
