#!/bin/bash
# run_mariadb.sh - third engine: MariaDB 11.4, system-versioned table plus row-based binary log.
# Run from the experiments folder. Needs the dasfaa-mariadb container (see the README / chat
# instructions). No password export needed: the container uses a lab-only root password.
#   TRIALS=1 SCALES="1000" ./run_mariadb.sh     smoke test (about 1 minute)
#   ./run_mariadb.sh                            full run: 3 trials, scales 1000 and 100000
# Per trial: fresh database, empty binary log, 1,000 or 100,000 synthetic subjects, an unrelated
# update of 9 other subjects (so they have history too), then 100 subjects erased by DELETE or
# by overwriting UPDATE. Counts residue in the history and in the binary log, then tries three
# remedies. Output: ../results/md1_mariadb.csv and ../results/md1_mariadb.log
TRIALS="${TRIALS:-3}"
SCALES="${SCALES:-1000 100000}"
RES="../results"; CSV="$RES/md1_mariadb.csv"; LOG="$RES/md1_mariadb.log"
C=dasfaa-mariadb; PW='Lab-only-2027'
q () { docker exec "$C" mariadb -uroot -p"$PW" -N -B -e "$1" < /dev/null 2>>"$LOG"; }
qs () { docker exec "$C" mariadb -uroot -p"$PW" -N -B -e "$1" < /dev/null > /dev/null 2>>"$LOG" && echo ok || echo error; }
# erased subjects: ids 10, 20, ..., 1000 (100 subjects)
ERASED="id <= 1000 AND id % 10 = 0"
OTHERS="id BETWEEN 1 AND 9"          # not erased; given history by an unrelated update
binlog_count () {   # prints "<occurrences> <distinct erased subjects>" over all binary log files
  local files; files=$(q "SHOW BINARY LOGS" | awk '{print "/var/lib/mysql/"$1}')
  docker exec "$C" sh -c "mariadb-binlog -v --base64-output=DECODE-ROWS $files 2>/dev/null" < /dev/null \
    | grep -oE "'subject[0-9]+@example\.invalid'" | tr -d "'" | sed 's/subject//; s/@example.invalid//' \
    | awk '$1 <= 1000 && $1 % 10 == 0 {n++; s[$1]=1} END {print n+0, length(s)+0}'
}
docker exec "$C" mariadb-admin -uroot -p"$PW" ping < /dev/null > /dev/null 2>&1 || { echo "Container $C is not ready. Stopping."; exit 1; }
[ -f "$CSV" ] || echo "scale,method,trial,binlog_format,binlog_row_image,binlog_expire_logs_seconds,src_rows_readable,history_rows,history_subjects,binlog_copies,binlog_subjects,delete_one_history_row_for_system_time,delete_history_where_id,subject10_history_left,other_erased_history_left,others_history_before,erased_history_left_after_delete_history,others_history_left_after_delete_history,purge_tries,binlog_subjects_after_purge" > "$CSV"
for scale in $SCALES; do for method in DELETE UPDATE; do for t in $(seq 1 "$TRIALS"); do
  echo "--- mariadb scale=$scale method=$method trial=$t ($(date +%T))" | tee -a "$LOG"
  q "DROP DATABASE IF EXISTS md_lab; RESET MASTER;"
  q "CREATE DATABASE md_lab; USE md_lab;
     CREATE TABLE customer (id INT PRIMARY KEY, full_name VARCHAR(100), email VARCHAR(200), phone VARCHAR(30)) WITH SYSTEM VERSIONING;
     INSERT INTO customer SELECT seq, CONCAT('Subject_', seq), CONCAT('subject', seq, '@example.invalid'), CONCAT('+1-555-', seq) FROM seq_1_to_$scale;
     UPDATE customer SET phone = CONCAT(phone, '-x') WHERE $OTHERS;"
  if [ "$method" = DELETE ]; then q "DELETE FROM md_lab.customer WHERE $ERASED;"
  else q "UPDATE md_lab.customer SET full_name='REDACTED', email='redacted@example.invalid', phone=NULL WHERE $ERASED;"; fi
  CFG=$(q "SELECT CONCAT_WS(',', @@binlog_format, @@binlog_row_image, @@binlog_expire_logs_seconds)")
  SRC=$(q "SELECT COUNT(*) FROM md_lab.customer WHERE $ERASED AND email LIKE 'subject%'")
  HIST=$(q "SELECT CONCAT(COUNT(*), ',', COUNT(DISTINCT id)) FROM md_lab.customer FOR SYSTEM_TIME ALL WHERE $ERASED AND email LIKE 'subject%'")
  read BOCC BSUB <<< "$(binlog_count)"
  # remedy 1: remove one subject's history row, two ways
  R1=$(qs "DELETE FROM md_lab.customer FOR SYSTEM_TIME ALL WHERE id = 10")
  R1B=$(qs "DELETE HISTORY FROM md_lab.customer WHERE id = 10")
  R1C=$(q "SELECT CONCAT(SUM(id = 10), ',', SUM(id <> 10)) FROM md_lab.customer FOR SYSTEM_TIME ALL WHERE $ERASED AND email LIKE 'subject%'")
  R2PRE=$(q "SELECT COUNT(*) FROM md_lab.customer FOR SYSTEM_TIME ALL WHERE $OTHERS AND row_end < '2038-01-01'")
  # remedy 2: DELETE HISTORY (removes all history before the given time, for every row)
  q "DELETE HISTORY FROM md_lab.customer BEFORE SYSTEM_TIME NOW(6);"
  R2A=$(q "SELECT COUNT(*) FROM md_lab.customer FOR SYSTEM_TIME ALL WHERE $ERASED AND email LIKE 'subject%'")
  R2B=$(q "SELECT COUNT(*) FROM md_lab.customer FOR SYSTEM_TIME ALL WHERE $OTHERS AND row_end < '2038-01-01'")
  # remedy 3: rotate and purge the binary log
  q "FLUSH BINARY LOGS;"
  NEWEST=$(q "SHOW BINARY LOGS" | tail -1 | awk '{print $1}')
  # PURGE can return without removing a file that is still needed for crash recovery, so repeat
  # it once a second until only the newest file is left, and record how many tries that took
  TRIES=0
  while [ "$TRIES" -lt 60 ]; do
    TRIES=$((TRIES + 1))
    q "PURGE BINARY LOGS TO '$NEWEST';"
    [ "$(q "SHOW BINARY LOGS" | wc -l | tr -d ' ')" -le 1 ] && break
    sleep 1
  done
  read _ R3 <<< "$(binlog_count)"
  echo "$scale,$method,$t,$CFG,$SRC,$HIST,$BOCC,$BSUB,$R1,$R1B,$R1C,$R2PRE,$R2A,$R2B,$TRIES,$R3" | tee -a "$CSV"
done; done; done
