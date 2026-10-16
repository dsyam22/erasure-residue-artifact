-- p1_pg_slot_residue.sql  (PostgreSQL 17)
-- PostgreSQL counterpart of SQL Server scenarios 1 and 3.
-- A logical replication slot is PostgreSQL's change-data-capture mechanism: it makes the
-- server keep its write-ahead log so a consumer can read row changes from it.
--
--   customer : default REPLICA IDENTITY (delete records carry the key only)
--   member   : REPLICA IDENTITY FULL    (delete/update records carry the whole old row)
--
--   Part A: erase subject 42 with DELETE, and subject 77 by overwriting with UPDATE.
--   Part B: what can still be read about those subjects through the slot?
--   Part C: how much log does the unread slot hold back, and is there a limit?
--   Part D: after a consumer reads the slot, is anything still readable through it?
-- Rerunnable. Synthetic data only.
\pset pager off
SELECT 'CREATE DATABASE erasure_lab_pg'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'erasure_lab_pg')\gexec
\c erasure_lab_pg

SELECT pg_drop_replication_slot(slot_name)
FROM pg_replication_slots WHERE slot_name = 'audit_slot' AND NOT active;
DROP TABLE IF EXISTS customer, member;

CREATE TABLE customer (
    customer_id int PRIMARY KEY, full_name text NOT NULL, email text NOT NULL, phone text);
CREATE TABLE member (
    member_id   int PRIMARY KEY, full_name text NOT NULL, email text NOT NULL, phone text);
ALTER TABLE member REPLICA IDENTITY FULL;

SELECT slot_name FROM pg_create_logical_replication_slot('audit_slot', 'test_decoding');

INSERT INTO customer
SELECT i, 'Subject_' || lpad(i::text, 6, '0'), 'subject' || i || '@example.invalid',
       '+1-555-' || lpad(i::text, 4, '0')
FROM generate_series(1, 1000) AS i;
INSERT INTO member SELECT * FROM customer;

\echo --- Run timestamp (UTC) ---
SELECT now() AT TIME ZONE 'utc' AS run_started_utc;

\echo === PART A: erase subject 42 (DELETE) and subject 77 (overwrite) in both tables ===
DELETE FROM customer WHERE customer_id = 42;
DELETE FROM member   WHERE member_id   = 42;
UPDATE customer SET full_name = 'REDACTED', email = 'redacted@example.invalid', phone = NULL
WHERE customer_id = 77;
UPDATE member   SET full_name = 'REDACTED', email = 'redacted@example.invalid', phone = NULL
WHERE member_id = 77;

\echo --- Source tables after erasure ---
SELECT 'customer' AS tbl, customer_id AS id, full_name, email, phone FROM customer WHERE customer_id IN (42, 77)
UNION ALL
SELECT 'member', member_id, full_name, email, phone FROM member WHERE member_id IN (42, 77);

\echo === PART B: what the slot still returns for subjects 42 and 77 (peek does not consume) ===
SELECT data
FROM pg_logical_slot_peek_changes('audit_slot', NULL, NULL)
WHERE data ~ '_id\[integer\]:(42|77)( |$)';

\echo === PART C: log held back by the unread slot ===
SELECT slot_name, plugin, active, wal_status,
       pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(), restart_lsn)) AS log_held_back
FROM pg_replication_slots WHERE slot_name = 'audit_slot';
\echo --- Limit on how much log a slot may hold back (-1 = no limit) ---
SHOW max_slot_wal_keep_size;

\echo === PART D: a consumer reads the slot ===
SELECT count(*) AS changes_consumed FROM pg_logical_slot_get_changes('audit_slot', NULL, NULL);
\echo --- Rows for subjects 42 and 77 still readable through the slot ---
SELECT count(*) AS still_readable
FROM pg_logical_slot_peek_changes('audit_slot', NULL, NULL)
WHERE data ~ '_id\[integer\]:(42|77)( |$)';
