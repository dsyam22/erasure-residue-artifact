-- pm3_access.sql - which PostgreSQL roles can read a replication slot.
-- Run in database postgres as the superuser. Creates and removes its own slot and roles.
\set ON_ERROR_STOP off
DROP ROLE IF EXISTS pm3_reader;
DROP ROLE IF EXISTS pm3_repl;
CREATE ROLE pm3_reader;
GRANT pg_read_all_data TO pm3_reader;
CREATE ROLE pm3_repl REPLICATION;
SELECT 'slot created: ' || slot_name FROM pg_create_logical_replication_slot('pm3_slot', 'test_decoding');
\echo === 1. role with pg_read_all_data but without REPLICATION (an error is the expected result)
SET ROLE pm3_reader;
SELECT current_user, count(*) AS changes_readable FROM pg_logical_slot_peek_changes('pm3_slot', NULL, NULL);
RESET ROLE;
\echo === 2. role with REPLICATION
SET ROLE pm3_repl;
SELECT current_user, count(*) AS changes_readable FROM pg_logical_slot_peek_changes('pm3_slot', NULL, NULL);
RESET ROLE;
SELECT pg_drop_replication_slot('pm3_slot');
DROP ROLE pm3_reader;
DROP ROLE pm3_repl;
\echo === done
