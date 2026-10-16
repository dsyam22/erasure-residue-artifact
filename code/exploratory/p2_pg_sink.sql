-- p2_pg_sink.sql  (PostgreSQL 17)
-- PostgreSQL counterpart of SQL Server scenario 5 (downstream copy).
-- Source database erasure_lab_pg publishes table subscriber; database sink_lab_pg
-- subscribes to it using PostgreSQL's built-in logical replication.
--
--   Part A: subscription keeps up. Delete subject 42 at the source. Does the sink lose it?
--   Part B: subscription is paused (lagging). Delete subject 43 at the source. The replication
--           slot is then dropped and recreated (an operational step used when an idle slot is
--           holding back log), and the subscription is resumed. Does the delete reach the sink?
--   Part C: is replication still working afterwards (a new row arrives)?
-- Rerunnable. Synthetic data only. Takes about 40 seconds.
\pset pager off
SELECT 'CREATE DATABASE erasure_lab_pg'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'erasure_lab_pg')\gexec
SELECT 'CREATE DATABASE sink_lab_pg'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'sink_lab_pg')\gexec

-- Clean up a previous run
\c sink_lab_pg
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_subscription s JOIN pg_database d ON d.oid = s.subdbid
               WHERE s.subname = 'sink_sub' AND d.datname = current_database()) THEN
        ALTER SUBSCRIPTION sink_sub DISABLE;
        ALTER SUBSCRIPTION sink_sub SET (slot_name = NONE);
        DROP SUBSCRIPTION sink_sub;
    END IF;
END $$;
DROP TABLE IF EXISTS subscriber;
SELECT pg_sleep(3);

\c erasure_lab_pg
SELECT pg_drop_replication_slot(slot_name)
FROM pg_replication_slots WHERE slot_name = 'sink_sub' AND NOT active;
DROP PUBLICATION IF EXISTS sink_pub;
DROP TABLE IF EXISTS subscriber;

CREATE TABLE subscriber (subscriber_id int PRIMARY KEY, full_name text NOT NULL, email text NOT NULL);
INSERT INTO subscriber
SELECT i, 'Subject_' || lpad(i::text, 6, '0'), 'subject' || i || '@example.invalid'
FROM generate_series(1, 100) AS i;
CREATE PUBLICATION sink_pub FOR TABLE subscriber;
SELECT slot_name FROM pg_create_logical_replication_slot('sink_sub', 'pgoutput');

\c sink_lab_pg
CREATE TABLE subscriber (subscriber_id int PRIMARY KEY, full_name text NOT NULL, email text NOT NULL);
CREATE SUBSCRIPTION sink_sub
    CONNECTION 'dbname=erasure_lab_pg user=postgres'
    PUBLICATION sink_pub
    WITH (create_slot = false, slot_name = 'sink_sub', copy_data = true);
SELECT pg_sleep(8);

\echo --- Run timestamp (UTC) ---
SELECT now() AT TIME ZONE 'utc' AS run_started_utc;
\echo --- Initial copy: rows in the sink ---
SELECT count(*) AS sink_rows FROM subscriber;

\echo === PART A: subscription keeps up ===
\c erasure_lab_pg
DELETE FROM subscriber WHERE subscriber_id = 42;
\c sink_lab_pg
SELECT pg_sleep(5);
\echo --- Subject 42 in the sink (no rows = delete propagated) ---
SELECT * FROM subscriber WHERE subscriber_id = 42;

\echo === PART B: subscription paused, slot dropped and recreated ===
ALTER SUBSCRIPTION sink_sub DISABLE;
SELECT pg_sleep(4);
\c erasure_lab_pg
DELETE FROM subscriber WHERE subscriber_id = 43;
\echo --- Slot state before it is dropped ---
SELECT slot_name, active, wal_status,
       pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(), confirmed_flush_lsn)) AS unread_log
FROM pg_replication_slots WHERE slot_name = 'sink_sub';
SELECT pg_drop_replication_slot('sink_sub');
SELECT slot_name FROM pg_create_logical_replication_slot('sink_sub', 'pgoutput');
\c sink_lab_pg
ALTER SUBSCRIPTION sink_sub ENABLE;
SELECT pg_sleep(8);

\echo === PART C: is replication still working? Insert subject 501 at the source ===
\c erasure_lab_pg
INSERT INTO subscriber VALUES (501, 'Subject_000501', 'subject501@example.invalid');
\echo --- Subject 43 in the source ---
SELECT count(*) AS source_rows_for_subject_43 FROM subscriber WHERE subscriber_id = 43;
SELECT count(*) AS source_rows FROM subscriber;
\c sink_lab_pg
SELECT pg_sleep(5);
\echo --- Subject 501 in the sink (a row = replication is running) ---
SELECT * FROM subscriber WHERE subscriber_id = 501;
\echo --- Subject 43 in the sink (a row here = erased at source, still present downstream) ---
SELECT * FROM subscriber WHERE subscriber_id = 43;
SELECT count(*) AS sink_rows FROM subscriber;
\echo --- Subscription health as PostgreSQL reports it ---
SELECT subname, subenabled FROM pg_subscription WHERE subname = 'sink_sub';
SELECT subname, apply_error_count, sync_error_count FROM pg_stat_subscription_stats WHERE subname = 'sink_sub';
