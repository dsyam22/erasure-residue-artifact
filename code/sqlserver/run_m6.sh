#!/bin/bash
# run_m6.sh - access model, per-subject removal, second capture instance, dropped-column remedy.
# Run from the experiments folder with MSSQL_SA_PASSWORD exported:
#   TRIALS=1 ./run_m6.sh     smoke test
#   ./run_m6.sh              3 trials
# Output: ../results/m6_remedies.csv (trial,key,value) and ../results/m6_remedies.log
TRIALS="${TRIALS:-3}"
RES="../results"
if [ -z "$MSSQL_SA_PASSWORD" ]; then echo "MSSQL_SA_PASSWORD is not set in this window. Stopping."; exit 1; fi
docker cp m6_remedies.sql dasfaa-mssql:/tmp/m6_remedies.sql > /dev/null || { echo "copy failed"; exit 1; }
[ -f "$RES/m6_remedies.csv" ] || echo "trial,key,value" > "$RES/m6_remedies.csv"
for t in $(seq 1 "$TRIALS"); do
  echo "--- m6 trial $t ($(date +%T))"
  docker exec dasfaa-mssql /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "$MSSQL_SA_PASSWORD" \
      -C -W -h -1 -i /tmp/m6_remedies.sql -v TRIAL="$t" < /dev/null 2>&1 | tee -a "$RES/m6_remedies.log" \
      | grep '^RESULT,' | sed 's/^RESULT,//' | tee -a "$RES/m6_remedies.csv"
done
