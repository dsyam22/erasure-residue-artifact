-- pm1_slot_residue.sql  (PostgreSQL measured run: residue readable through a replication slot)
-- psql variables: scale, identity (default | full), method (DELETE | UPDATE), trial, seed
-- Erases 100 seeded-random subjects, then counts what the slot still returns about them.
-- Prints one line starting with RESULT,
\c erasure_m_pg
SET client_min_messages = warning;
SELECT pg_drop_replication_slot(slot_name) FROM pg_replication_slots WHERE slot_name = 'm_slot' AND NOT active;
DROP TABLE IF EXISTS customer;
CREATE TABLE customer (customer_id int PRIMARY KEY, full_name text NOT NULL, email text NOT NULL, phone text);
SELECT :'identity' = 'full' AS is_full \gset
\if :is_full
ALTER TABLE customer REPLICA IDENTITY FULL;
\endif
SELECT slot_name FROM pg_create_logical_replication_slot('m_slot', 'test_decoding');

INSERT INTO customer
SELECT i, 'Subject_' || lpad(i::text, 7, '0'), 'subject' || i || '@example.invalid', '+1-555-' || lpad(i::text, 7, '0')
FROM generate_series(1, :scale) AS i;

CREATE TEMP TABLE erased AS
SELECT customer_id AS id FROM customer ORDER BY md5(customer_id::text || ':' || :'seed') LIMIT 100;

SELECT :'method' = 'DELETE' AS is_delete \gset
\if :is_delete
DELETE FROM customer WHERE customer_id IN (SELECT id FROM erased);
\else
UPDATE customer SET full_name = 'REDACTED', email = 'redacted@example.invalid', phone = NULL
WHERE customer_id IN (SELECT id FROM erased);
\endif

-- What the slot returns (peek does not consume)
CREATE TEMP TABLE ch AS
SELECT (regexp_match(data, '^table public\.customer: (INSERT|UPDATE|DELETE):'))[1] AS kind,
       (regexp_match(data, 'customer_id\[integer\]:(\d+)'))[1]::int AS id,
       position('Subject_' in data) > 0 AS has_original
FROM pg_logical_slot_peek_changes('m_slot', NULL, NULL)
WHERE data LIKE 'table public.customer:%';

SELECT pg_wal_lsn_diff(pg_current_wal_lsn(), restart_lsn)::bigint AS wal_held
FROM pg_replication_slots WHERE slot_name = 'm_slot' \gset
SELECT count(*) AS ins_readable FROM ch WHERE kind = 'INSERT' AND has_original AND id IN (SELECT id FROM erased) \gset
SELECT count(*) AS erase_records FROM ch WHERE kind <> 'INSERT' AND id IN (SELECT id FROM erased) \gset
SELECT count(*) AS erase_readable FROM ch WHERE kind <> 'INSERT' AND has_original AND id IN (SELECT id FROM erased) \gset
SELECT count(DISTINCT id) AS subjects_readable FROM ch WHERE has_original AND id IN (SELECT id FROM erased) \gset
SELECT count(*) AS src_readable FROM customer
WHERE customer_id IN (SELECT id FROM erased) AND full_name LIKE 'Subject%' \gset

-- A consumer reads the slot; is anything about the erased subjects still returned?
SELECT count(*) AS consumed FROM pg_logical_slot_get_changes('m_slot', NULL, NULL) \gset
SELECT count(*) AS still_readable
FROM pg_logical_slot_peek_changes('m_slot', NULL, NULL)
WHERE data LIKE 'table public.customer:%'
  AND (regexp_match(data, 'customer_id\[integer\]:(\d+)'))[1]::int IN (SELECT id FROM erased) \gset

SELECT 'RESULT,' || concat_ws(',', :scale, :'identity', :'method', :trial, :seed,
       :src_readable, :ins_readable, :erase_records, :erase_readable, :subjects_readable,
       :wal_held, current_setting('max_slot_wal_keep_size'), :consumed, :still_readable);
