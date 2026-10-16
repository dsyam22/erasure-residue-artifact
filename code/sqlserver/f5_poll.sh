#!/bin/bash
# f5_poll.sh
# Records one line every 15 minutes to ../results/f5_run1.csv:
#   utc_time, engine_awake_hours, history_rows_direct, rows_via_time_travel
# Needs MSSQL_SA_PASSWORD exported in the terminal that starts it.
OUT="../results/f5_run1.csv"
if [ ! -f "$OUT" ]; then
  echo "utc_time,engine_awake_hours,history_rows_direct,rows_via_time_travel" > "$OUT"
fi
Q="SET NOCOUNT ON; SELECT CONVERT(varchar(19), SYSUTCDATETIME(), 120), CAST((ms_ticks - sqlserver_start_time_ms_ticks) / 3600000.0 AS DECIMAL(10,3)), (SELECT COUNT(*) FROM temporal_run.dbo.member_history WHERE member_id <= 100), (SELECT COUNT(*) FROM temporal_run.dbo.member FOR SYSTEM_TIME ALL WHERE member_id <= 100) FROM sys.dm_os_sys_info;"
while true; do
  docker exec -i dasfaa-mssql /opt/mssql-tools18/bin/sqlcmd \
    -S localhost -U sa -P "$MSSQL_SA_PASSWORD" -C -W -h -1 -s "," -Q "$Q" >> "$OUT" 2>&1
  sleep 900
done
