#!/bin/bash
# f6_run.sh - repeat of the temporal-retention measurement with five runs and one-minute polling.
# Run from the experiments folder with MSSQL_SA_PASSWORD exported:
#   nohup caffeinate -dimsu ./f6_run.sh > ../results/f6_run.log 2>&1 < /dev/null &
# Creates temporal_r1 .. temporal_r5, seven minutes apart, so that the five retention periods
# end at different moments. Polls every 15 minutes at first and every 60 seconds from 20
# minutes before the first period ends, until every run's rows are gone (or 8 hours later).
# Output: ../results/f6_temporal.csv
#   utc_time, run, seconds_since_erasure, history_rows_direct, rows_via_time_travel, engine_awake_hours
# The computer must stay awake for the whole run (about 26 hours); caffeinate does that.
RUNS="${RUNS:-5}"
GAP="${GAP:-420}"                 # seconds between the erasures of consecutive runs
OUT="../results/f6_temporal.csv"
if [ -z "$MSSQL_SA_PASSWORD" ]; then echo "MSSQL_SA_PASSWORD is not set in this window. Stopping."; exit 1; fi
sql () { docker exec dasfaa-mssql /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "$MSSQL_SA_PASSWORD" -C -W -h -1 -s "," "$@" < /dev/null 2>&1; }

if [ "$SKIP_SETUP" != 1 ]; then
  docker cp f6_setup.sql dasfaa-mssql:/tmp/f6_setup.sql > /dev/null || { echo "copy failed"; exit 1; }
  echo "utc_time,run,seconds_since_erasure,history_rows_direct,rows_via_time_travel,engine_awake_hours" > "$OUT"
  for r in $(seq 1 "$RUNS"); do
    sql -i /tmp/f6_setup.sql -v RUN="$r" | grep '^SETUP,' || { echo "setup of run $r failed"; exit 1; }
    [ "$r" -lt "$RUNS" ] && sleep "$GAP"
  done
fi

Q="SET NOCOUNT ON;"
for r in $(seq 1 "$RUNS"); do
  Q="$Q SELECT CONVERT(varchar(19), SYSUTCDATETIME(), 120), $r, DATEDIFF(SECOND, (SELECT erased_at FROM temporal_r$r.dbo.run_info), SYSUTCDATETIME()), (SELECT COUNT(*) FROM temporal_r$r.dbo.member_history WHERE member_id <= 100), (SELECT COUNT(*) FROM temporal_r$r.dbo.member FOR SYSTEM_TIME ALL WHERE member_id <= 100), (SELECT CAST((ms_ticks - sqlserver_start_time_ms_ticks) / 3600000.0 AS DECIMAL(10,3)) FROM sys.dm_os_sys_info);"
done

while true; do
  LINES=$(sql -Q "$Q")
  echo "$LINES" | grep '^20' >> "$OUT"
  echo "$LINES" | grep -v '^20' | grep -v '^$'            # anything unexpected goes to the log
  OLDEST=$(echo "$LINES" | grep '^20' | awk -F, '{print $3}' | sort -n | tail -1)
  LEFT=$(echo "$LINES" | grep '^20' | awk -F, '{s += $4} END {print s + 0}')
  if [ -n "$OLDEST" ] && [ "$OLDEST" -gt 86400 ] && [ "$LEFT" -eq 0 ]; then echo "All runs cleared at $(date -u +%FT%TZ). Done."; break; fi
  if [ -n "$OLDEST" ] && [ "$OLDEST" -gt 115200 ]; then echo "Stopping 8 hours after expiry with $LEFT rows left."; break; fi
  if [ -n "$OLDEST" ] && [ "$OLDEST" -ge 85200 ]; then sleep 60; else sleep 900; fi
done
