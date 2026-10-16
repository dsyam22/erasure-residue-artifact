-- pm2_sink.sql  (PostgreSQL measured run: downstream copy via built-in logical replication)
-- psql variable: trial
--   Part A: subscription keeps up; subjects 31-40 are deleted at the source.
--   Part B: subscription paused; subjects 41-50 are deleted; the slot is dropped and
--           recreated; the subscription is resumed; a marker row (501) is inserted at the
--           source and we wait for it to arrive before counting.
-- Prints one line starting with RESULT,
\c sink_m_pg
SET client_min_messages = warning;
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_subscription s JOIN pg_database d ON d.oid = s.subdbid
               WHERE s.subname = 'sink_sub_m' AND d.datname = current_database()) THEN
        ALTER SUBSCRIPTION sink_sub_m DISABLE;
        ALTER SUBSCRIPTION sink_sub_m SET (slot_name = NONE);
        DROP SUBSCRIPTION sink_sub_m;
    END IF;
END $$;
DROP TABLE IF EXISTS subscriber;

\c erasure_m_pg
SET client_min_messages = warning;
DO $$ DECLARE i int := 0;
BEGIN
    WHILE i < 60 AND EXISTS (SELECT 1 FROM pg_replication_slots WHERE slot_name = 'sink_sub_m' AND active) LOOP
        PERFORM pg_sleep(0.5); i := i + 1;
    END LOOP;
END $$;
SELECT pg_drop_replication_slot(slot_name) FROM pg_replication_slots WHERE slot_name = 'sink_sub_m' AND NOT active;
DROP PUBLICATION IF EXISTS sink_pub_m;
DROP TABLE IF EXISTS subscriber;
CREATE TABLE subscriber (subscriber_id int PRIMARY KEY, full_name text NOT NULL, email text NOT NULL);
INSERT INTO subscriber
SELECT i, 'Subject_' || lpad(i::text, 7, '0'), 'subject' || i || '@example.invalid' FROM generate_series(1, 100) AS i;
CREATE PUBLICATION sink_pub_m FOR TABLE subscriber;
SELECT slot_name FROM pg_create_logical_replication_slot('sink_sub_m', 'pgoutput');

\c sink_m_pg
SET client_min_messages = warning;
CREATE TABLE subscriber (subscriber_id int PRIMARY KEY, full_name text NOT NULL, email text NOT NULL);
CREATE SUBSCRIPTION sink_sub_m CONNECTION 'dbname=erasure_m_pg user=postgres' PUBLICATION sink_pub_m
    WITH (create_slot = false, slot_name = 'sink_sub_m', copy_data = true);
DO $$ DECLARE i int := 0;
BEGIN
    WHILE i < 120 AND (SELECT count(*) FROM subscriber) < 100 LOOP PERFORM pg_sleep(0.5); i := i + 1; END LOOP;
END $$;
SELECT count(*) AS sink_initial FROM subscriber \gset

-- Part A
\c erasure_m_pg
DELETE FROM subscriber WHERE subscriber_id BETWEEN 31 AND 40;
\c sink_m_pg
DO $$ DECLARE i int := 0;
BEGIN
    WHILE i < 120 AND EXISTS (SELECT 1 FROM subscriber WHERE subscriber_id BETWEEN 31 AND 40) LOOP
        PERFORM pg_sleep(0.5); i := i + 1;
    END LOOP;
END $$;
SELECT count(*) AS parta_left FROM subscriber WHERE subscriber_id BETWEEN 31 AND 40 \gset

-- Part B
ALTER SUBSCRIPTION sink_sub_m DISABLE;
\c erasure_m_pg
DO $$ DECLARE i int := 0;
BEGIN
    WHILE i < 60 AND EXISTS (SELECT 1 FROM pg_replication_slots WHERE slot_name = 'sink_sub_m' AND active) LOOP
        PERFORM pg_sleep(0.5); i := i + 1;
    END LOOP;
END $$;
DELETE FROM subscriber WHERE subscriber_id BETWEEN 41 AND 50;
SELECT pg_drop_replication_slot('sink_sub_m');
SELECT slot_name FROM pg_create_logical_replication_slot('sink_sub_m', 'pgoutput');
\c sink_m_pg
ALTER SUBSCRIPTION sink_sub_m ENABLE;
\c erasure_m_pg
INSERT INTO subscriber VALUES (501, 'Subject_0000501', 'subject501@example.invalid');
SELECT count(*) AS src_left FROM subscriber WHERE subscriber_id BETWEEN 41 AND 50 \gset
\c sink_m_pg
DO $$ DECLARE i int := 0;
BEGIN
    WHILE i < 120 AND NOT EXISTS (SELECT 1 FROM subscriber WHERE subscriber_id = 501) LOOP
        PERFORM pg_sleep(0.5); i := i + 1;
    END LOOP;
END $$;

SELECT 'RESULT,' || concat_ws(',', :trial, :sink_initial, :parta_left, :src_left,
       (SELECT count(*) FROM subscriber WHERE subscriber_id BETWEEN 41 AND 50),
       (SELECT count(*) FROM subscriber WHERE subscriber_id = 501),
       (SELECT subenabled::int FROM pg_subscription WHERE subname = 'sink_sub_m'),
       (SELECT apply_error_count FROM pg_stat_subscription_stats WHERE subname = 'sink_sub_m'),
       (SELECT sync_error_count  FROM pg_stat_subscription_stats WHERE subname = 'sink_sub_m'));
