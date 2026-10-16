#!/bin/bash
# run_overnight.sh - measured SQL Server runs for F6 (cleanup timing) and F7 (downstream sink).
# Each condition runs as its own stream, in its own database, in parallel; trials within a
# stream run one after another.
# Usage (from the experiments folder, with MSSQL_SA_PASSWORD exported):
#   TRIALS=1 RETS="1" ./run_overnight.sh     smoke test
#   ./run_overnight.sh                       full run: 10 trials, retention 1, 5, 15 minutes
# Output: ../results/m4_cleanup.csv, ../results/m5_sink.csv, ../results/overnight_*.log
TRIALS="${TRIALS:-10}"
RETS="${RETS:-1 5 15}"
RES="../results"

if [ -z "$MSSQL_SA_PASSWORD" ]; then echo "MSSQL_SA_PASSWORD is not set in this window. Stopping."; exit 1; fi
for f in m4_cleanup m5_sink; do
  docker cp "$f.sql" "dasfaa-mssql:/tmp/$f.sql" > /dev/null || { echo "copy of $f.sql failed"; exit 1; }
done

[ -f "$RES/m4_cleanup.csv" ] || echo "retention_min,activity,trial,erased_at,min_to_insert_image_gone,min_to_delete_record_gone,cleanup_runs_after_eligible_no_removal,cleanup_runs_total,change_rows_left,timed_out,read_errors,last_read_error" > "$RES/m4_cleanup.csv"
[ -f "$RES/m5_sink.csv" ]    || echo "consumer,trial,sink_rows_initial,partA_erased_left_in_sink,minutes_until_stream_cleared,change_rows_left_for_erased,partB_erased_left_in_source,partB_erased_left_in_sink,window_clamped,error_number,deletes_applied" > "$RES/m5_sink.csv"

run_sql () {   # $1 = script, $2 = csv, $3 = log tag, $4 = pattern a good result must match, rest = sqlcmd variables
  local script="$1" csv="$2" tag="$3" good="$4"; shift 4
  local log="$RES/overnight_$tag.log" line attempt
  for attempt in 1 2 3; do
    echo "=== $(date -u +%FT%TZ) $script $* (attempt $attempt) ===" >> "$log"
    line=$(docker exec dasfaa-mssql /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "$MSSQL_SA_PASSWORD" \
        -C -W -h -1 -i "/tmp/$script.sql" -v "$@" < /dev/null 2>&1 | tee -a "$log" \
        | grep '^RESULT,' | sed 's/^RESULT,//' | tail -n 1)
    if echo "$line" | grep -Eq "$good"; then
      echo "$line" >> "$csv"
      return 0
    fi
    echo "$(date +%T) $tag: attempt $attempt gave no complete result, retrying" | tee -a "$log"
    sleep 15
  done
  echo "$(date +%T) $tag: FAILED after 3 attempts ($*)" | tee -a "$log"
  return 1
}

cleanup_stream () {   # $1 = retention, $2 = activity
  for t in $(seq 1 "$TRIALS"); do
    run_sql m4_cleanup "$RES/m4_cleanup.csv" "cleanup_r$1_a$2" '^[0-9]+,[01],[0-9]+,20' DB="m_c_r$1_a$2" RET="$1" ACTIVITY="$2" TRIAL="$t"
    echo "$(date +%T) cleanup retention=$1 activity=$2 trial=$t done"
  done
}
sink_stream () {      # $1 = CLAMP or STRICT
  for t in $(seq 1 "$TRIALS"); do
    run_sql m5_sink "$RES/m5_sink.csv" "sink_$1" '^(CLAMP|STRICT),[0-9]+,100,[0-9]+,[0-9.]+,[0-9]+,[0-9]+,[0-9]+,[01],[0-9]+,[0-9]+$' DB="m_s_$1" CONSUMER="$1" TRIAL="$t"
    echo "$(date +%T) sink consumer=$1 trial=$t done"
  done
}

START=$(date +%s)
echo "$(date +%T) starting: trials=$TRIALS retentions=$RETS"
for r in $RETS; do
  cleanup_stream "$r" 0 &
  sleep 5
  cleanup_stream "$r" 1 &
  sleep 5
done
sink_stream CLAMP &
sleep 5
sink_stream STRICT &
wait
echo "Finished in $(( ($(date +%s) - START) / 60 )) minutes."
