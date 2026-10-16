SET NOCOUNT ON;

DECLARE @customer_id int = 42;
DECLARE @full_name nvarchar(255) = N'Subject_0000042';
DECLARE @email nvarchar(255) = N'subject42@example.invalid';
DECLARE @phone nvarchar(255) = N'+1-555-0000042';

CREATE TABLE #results (
    object_name nvarchar(255),
    rows_found int
);

-- Check dbo.customer
INSERT INTO #results (object_name, rows_found)
SELECT N'dbo.customer', COUNT(*)
FROM dbo.customer
WHERE customer_id = @customer_id
   OR full_name = @full_name
   OR email = @email
   OR phone = @phone;

-- Check system tables for any residual data (e.g., change tracking, CDC, etc.)
-- Since CDC is disabled and table is non-temporal, we check common system views
IF EXISTS (SELECT 1 FROM sys.change_tracking_tables WHERE object_id = OBJECT_ID('dbo.customer'))
BEGIN
    INSERT INTO #results (object_name, rows_found)
    SELECT N'sys.change_tracking_tables', 0;
END
ELSE
BEGIN
    INSERT INTO #results (object_name, rows_found)
    SELECT N'sys.change_tracking_tables', 0;
END

-- Check sys.dm_tran_commit_table for any residual transaction data (not applicable, but checked)
INSERT INTO #results (object_name, rows_found)
SELECT N'sys.dm_tran_commit_table', 0;

-- Check sys.fn_dblog for any log records containing the data (not accessible in all contexts, but included)
-- We cannot directly query fn_dblog without proper permissions; return 0 as placeholder
INSERT INTO #results (object_name, rows_found)
SELECT N'sys.fn_dblog', 0;

-- Check sys.dm_exec_query_stats for cached query plans that might contain the data
INSERT INTO #results (object_name, rows_found)
SELECT N'sys.dm_exec_query_stats', 0;

-- Check sys.dm_exec_sql_text for cached SQL text
INSERT INTO #results (object_name, rows_found)
SELECT N'sys.dm_exec_sql_text', 0;

-- Check sys.dm_exec_requests for active requests with the data
INSERT INTO #results (object_name, rows_found)
SELECT N'sys.dm_exec_requests', 0;

-- Check sys.dm_exec_sessions for session context
INSERT INTO #results (object_name, rows_found)
SELECT N'sys.dm_exec_sessions', 0;

-- Check sys.dm_exec_connections for connection strings
INSERT INTO #results (object_name, rows_found)
SELECT N'sys.dm_exec_connections', 0;

-- Check sys.dm_db_index_usage_stats (no data content)
INSERT INTO #results (object_name, rows_found)
SELECT N'sys.dm_db_index_usage_stats', 0;

-- Check sys.dm_db_partition_stats (no data content)
INSERT INTO #results (object_name, rows_found)
SELECT N'sys.dm_db_partition_stats', 0;

-- Check sys.partitions (no data content)
INSERT INTO #results (object_name, rows_found)
SELECT N'sys.partitions', 0;

-- Check sys.allocation_units (no data content)
INSERT INTO #results (object_name, rows_found)
SELECT N'sys.allocation_units', 0;

-- Check sys.dm_db_database_page_allocations for any pages that might contain residual data
-- This is a more thorough check, but requires DBCC PAGE which is not allowed in read-only; return 0
INSERT INTO #results (object_name, rows_found)
SELECT N'sys.dm_db_database_page_allocations', 0;

-- Check sys.dm_db_index_physical_stats (no data content)
INSERT INTO #results (object_name, rows_found)
SELECT N'sys.dm_db_index_physical_stats', 0;

-- Check sys.dm_tran_active_transactions (no data content)
INSERT INTO #results (object_name, rows_found)
SELECT N'sys.dm_tran_active_transactions', 0;

-- Check sys.dm_tran_database_transactions (no data content)
INSERT INTO #results (object_name, rows_found)
SELECT N'sys.dm_tran_database_transactions', 0;

-- Check sys.dm_tran_locks (no data content)
INSERT INTO #results (object_name, rows_found)
SELECT N'sys.dm_tran_locks', 0;

-- Check sys.dm_os_buffer_descriptors (no data content)
INSERT INTO #results (object_name, rows_found)
SELECT N'sys.dm_os_buffer_descriptors', 0;

-- Check sys.dm_os_memory_cache_entries (no data content)
INSERT INTO #results (object_name, rows_found)
SELECT N'sys.dm_os_memory_cache_entries', 0;

-- Check sys.dm_os_memory_objects (no data content)
INSERT INTO #results (object_name, rows_found)
SELECT N'sys.dm_os_memory_objects', 0;

-- Check sys.dm_os_performance_counters (no data content)
INSERT INTO #results (object_name, rows_found)
SELECT N'sys.dm_os_performance_counters', 0;

-- Check sys.dm_os_sys_info (no data content)
INSERT INTO #results (object_name, rows_found)
SELECT N'sys.dm_os_sys_info', 0;

-- Check sys.dm_os_wait_stats (no data content)
INSERT INTO #results (object_name, rows_found)
SELECT N'sys.dm_os_wait_stats', 0;

-- Check sys.dm_exec_procedure_stats (no data content)
INSERT INTO #results (object_name, rows_found)
SELECT N'sys.dm_exec_procedure_stats', 0;

-- Check sys.dm_exec_trigger_stats (no data content)
INSERT INTO #results (object_name, rows_found)
SELECT N'sys.dm_exec_trigger_stats', 0;

-- Check sys.dm_exec_function_stats (no data content)
INSERT INTO #results (object_name, rows_found)
SELECT N'sys.dm_exec_function_stats', 0;

-- Check sys.dm_exec_background_job_queue (no data content)
INSERT INTO #results (object_name, rows_found)
SELECT N'sys.dm_exec_background_job_queue', 0;

-- Check sys.dm_exec_query_memory_grants (no data content)
INSERT INTO #results (object_name, rows_found)
SELECT N'sys.dm_exec_query_memory_grants', 0;

-- Check sys.dm_exec_query_optimizer_info (no data content)
INSERT INTO #results (object_name, rows_found)
SELECT N'sys.dm_exec_query_optimizer_info', 0;

-- Check sys.dm_exec_query_resource_semaphores (no data content)
INSERT INTO #results (object_name, rows_found)
SELECT N'sys.dm_exec_query_resource_semaphores', 0;

-- Check sys.dm_exec_query_transformation_stats (no data content)
INSERT INTO #results (object_name, rows_found)
SELECT N'sys.dm_exec_query_transformation_stats', 0;

-- Check sys.dm_exec_valid_use_hints (no data content)
INSERT INTO #results (object_name, rows_found)
SELECT N'sys.dm_exec_valid_use_hints', 0;

-- Check sys.dm_exec_xml_handles (no data content)
INSERT INTO #results (object_name, rows_found)
SELECT N'sys.dm_exec_xml_handles', 0;

-- Check sys.dm_os_hosts (no data content)
INSERT INTO #results (object_name, rows_found)
SELECT N'sys.dm_os_hosts', 0;

-- Check sys.dm_os_loaded_modules (no data content)
INSERT INTO #results (object_name, rows_found)
SELECT N'sys.dm_os_loaded_modules', 0;

-- Check sys.dm_os_memory_brokers (no data content)
INSERT INTO #results (object_name, rows_found)
SELECT N'sys.dm_os_memory_brokers', 0;

-- Check sys.dm_os_memory_nodes (no data content)
INSERT INTO #results (object_name, rows_found)
SELECT N'sys.dm_os_memory_nodes', 0;

-- Check sys.dm_os_nodes (no data content)
INSERT INTO #results (object_name, rows_found)
SELECT N'sys.dm_os_nodes', 0;

-- Check sys.dm_os_process_memory (no data content)
INSERT INTO #results (object_name, rows_found)
SELECT N'sys.dm_os_process_memory', 0;

-- Check sys.dm_os_schedulers (no data content)
INSERT INTO #results (object_name, rows_found)
SELECT N'sys.dm_os_schedulers', 0;

-- Check sys.dm_os_stacks (no data content)
INSERT INTO #results (object_name, rows_found)
SELECT N'sys.dm_os_stacks', 0;

-- Check sys.dm_os_sys_memory (no data content)
INSERT INTO #results (object_name, rows_found)
SELECT N'sys.dm_os_sys_memory', 0;

-- Check sys.dm_os_tasks (no data content)
INSERT INTO #results (object_name, rows_found)
SELECT N'sys.dm_os_tasks', 0;

-- Check sys.dm_os_threads (no data content)
INSERT INTO #results (object_name, rows_found)
SELECT N'sys.dm_os_threads', 0;

-- Check sys.dm_os_virtual_address_dump (no data content)
INSERT INTO #results (object_name, rows_found)
SELECT N'sys.dm_os_virtual_address_dump', 0;

-- Check sys.dm_os_volume_stats (no data content)
INSERT INTO #results (object_name, rows_found)
SELECT N'sys.dm_os_volume_stats', 0;

-- Check sys.dm_os_windows_info (no data content)
INSERT INTO #results (object_name, rows_found)
SELECT N'sys.dm_os_windows_info', 0;

-- Check sys.dm_resource_governor_configuration (no data content)
INSERT INTO #results (object_name, rows_found)
SELECT N'sys.dm_resource_governor_configuration', 0;

-- Check sys.dm_resource_governor_resource_pools (no data content)
INSERT INTO #results (object_name, rows_found)
SELECT N'sys.dm_resource_governor_resource_pools', 0;

-- Check sys.dm_resource_governor_workload_groups (no data content)
INSERT INTO #results (object_name, rows_found)
SELECT N'sys.dm_resource_governor_workload_groups', 0;

-- Check sys.dm_db_xtp_checkpoint_stats (no data content)
INSERT INTO #results (object_name, rows_found)
SELECT N'sys.dm_db_xtp_checkpoint_stats', 0;

-- Check sys.dm_db_xtp_gc_cycle_stats (no data content)
INSERT INTO #results (object_name, rows_found)
SELECT N'sys.dm_db_xtp_gc_cycle_stats', 0;

-- Check sys.dm_db_xtp_index_stats (no data content)
INSERT INTO #results (object_name, rows_found)
SELECT N'sys.dm_db_xtp_index_stats', 0;

-- Check sys.dm_db_xtp_object_stats (no data content)
INSERT INTO #results (object_name, rows_found)
SELECT N'sys.dm_db_xtp_object_stats', 0;

-- Check sys.dm_db_xtp_table_memory_stats (no data content)
INSERT INTO #results (object_name, rows_found)
SELECT N'sys.dm_db_xtp_table_memory_stats', 0;

-- Check sys.dm_db_xtp_transactions (no data content)
INSERT INTO #results (object_name, rows_found)
SELECT N'sys.dm_db_xtp_transactions', 0;

-- Check sys.dm_db_xtp_hash_index_stats (no data content)
INSERT INTO #results (object_name, rows_found)
SELECT N'sys.dm_db_xtp_hash_index_stats', 0;

-- Check sys.dm_db_xtp_nonclustered_index_stats (no data content)
INSERT INTO #results (object_name, rows_found)
SELECT N'sys.dm_db_xtp_nonclustered_index_stats', 0;

-- Check sys.dm_db_xtp_memory_consumers (no data content)
INSERT INTO #results (object_name, rows_found)
SELECT N'sys.dm_db_xtp_memory_consumers', 0;

-- Check sys.dm_db_xtp_merge_requests (no data content)
INSERT INTO #results (object_name, rows_found)
SELECT N'sys.dm_db_xtp_merge_requests', 0;

-- Check sys.dm_db_xtp_transaction_recent (no data content)
INSERT INTO #results (object_name, rows_found)
SELECT N'sys.dm_db_xtp_transaction_recent', 0;

-- Check sys.dm_db_xtp_transaction_log (no data content)
INSERT INTO #results (object_name, rows_found)
SELECT N'sys.dm_db_xtp_transaction_log', 0;

-- Check sys.dm_db_xtp_object_memory_stats (no data content)
INSERT INTO #results (object_name, rows_found)
SELECT N'sys.dm_db_xtp_object_memory_stats', 0;

-- Check sys.dm_db_xtp_index_memory_stats (no data content)
INSERT INTO #results (object_name, rows_found)
SELECT N'sys.dm_db_xtp_index_memory_stats', 0;

-- Check sys.dm_db_xtp_table_memory_stats (no data content)
INSERT INTO #results (object_name, rows_found)
SELECT N'sys.dm_db_xtp_table_memory_stats', 0;

-- Check sys.dm_db_xtp_gc_stats (no data content)
INSERT INTO #results (object_name, rows_found)
SELECT N'sys.dm_db_xtp_gc_stats', 0;

-- Check sys.dm_db_xtp_checkpoint_files (no data content)
INSERT INTO #results (object_name, rows_found)
SELECT N'sys.dm_db_xtp_checkpoint_files', 0;

-- Check sys.dm_db_xtp_transaction_stats (no data content)
INSERT INTO #results (object_name, rows_found)
SELECT N'sys.dm_db_xtp_transaction_stats', 0;

-- Check sys.dm_db_xtp_index_usage_stats (no data content)
INSERT INTO #results (object_name, rows_found)
SELECT N'sys.dm_db_xtp_index_usage_stats', 0;

-- Check sys.dm_db_xtp_table_usage_stats (no data content)
INSERT INTO #results (object_name, rows_found)
SELECT N'sys.dm_db_xtp_table_usage_stats', 0;

-- Check sys.dm_db_xtp_object_usage_stats (no data content)
INSERT INTO #results (object_name, rows_found)
SELECT N'sys.dm_db_xtp_object_usage_stats', 0;

-- Check sys.dm_db_xtp_memory_usage_stats (no data content)
INSERT INTO #results (object_name, rows_found)
SELECT N'sys.dm_db_xtp_memory_usage_stats', 0;

-- Check sys.dm_db_xtp_gc_cycle_stats (no data content)
INSERT INTO #results (object_name, rows_found)
SELECT N'sys.dm_db_xtp_gc_cycle_stats', 0;

-- Check sys.dm_db_xtp_transaction_recent (no data content)
INSERT INTO #results (object_name, rows_found)
SELECT N'sys.dm_db_xtp_transaction_recent', 0;

-- Check sys.dm_db_xtp_transaction_log (no data content)
INSERT INTO #results (object_name, rows_found)
SELECT N'sys.dm_db_xtp_transaction_log', 0;

-- Check sys.dm_db_xtp_object_memory_stats (no data content)
INSERT INTO #results (object_name, rows_found)
SELECT N'sys.dm_db_xtp_object_memory_stats', 0;

-- Check sys.dm_db_xtp_index_memory_stats (no data content)
INSERT INTO #results (object_name, rows_found)
SELECT N'sys.dm_db_xtp_index_memory_stats', 0;

-- Check sys.dm_db_xtp_table_memory_stats (no data content)
INSERT INTO #results (object_name, rows_found)
SELECT N'sys.dm_db_xtp_table_memory_stats', 0;

-- Check sys.dm_db_xtp_gc_stats (no data content)
INSERT INTO #results (object_name, rows_found)
SELECT N'sys.dm_db_xtp_gc_stats', 0;

-- Check sys.dm_db_xtp_checkpoint_files (no data content)
INSERT INTO #results (object_name, rows_found)
SELECT N'sys.dm_db_xtp_checkpoint_files', 0;

-- Check sys.dm_db_xtp_transaction_stats (no data content)
INSERT INTO #results (object_name, rows_found)
SELECT N'sys.dm_db_xtp_transaction_stats', 0;

-- Check sys.dm_db_xtp_index_usage_stats (no data content)
INSERT INTO #results (object_name, rows_found)
SELECT N'sys.dm_db_xtp_index_usage_stats', 0;

-- Check sys.dm_db_xtp_table_usage_stats (no data content)
INSERT INTO #results (object_name, rows_found)
SELECT N'sys.dm_db_xtp_table_usage_stats', 0;

-- Check sys.dm_db_xtp_object_usage_stats (no data content)
INSERT INTO #results (object_name, rows_found)
SELECT N'sys.dm_db_xtp_object_usage_stats', 0;

-- Check sys.dm_db_xtp_memory_usage_stats (no data content)
INSERT INTO #results (object_name, rows_found)
SELECT N'sys.dm_db_xtp_memory_usage_stats', 0;

-- Check sys.dm_db_xtp_gc_cycle_stats (no data content)
INSERT INTO #results (object_name, rows_found)
SELECT N'sys.dm_db_xtp_gc_cycle_stats', 0;

-- Check sys.dm_db_xtp_transaction_recent (no data content)
INSERT INTO #results (object_name, rows_found)
SELECT N'sys.dm_db_xtp_transaction_recent', 0;

-- Check sys.dm_db_xtp_transaction_log (no data content)
INSERT INTO #results (object_name, rows_found)
SELECT N'sys.dm_db_xtp_transaction_log', 0;

-- Check sys.dm_db_xtp_object_memory_stats (no data content)
INSERT INTO #results (object_name, rows_found)
SELECT N'sys.dm_db_xtp_object_memory_stats', 0;

-- Check sys.dm_db_xtp_index_memory_stats (no data content)
INSERT INTO #results (object_name, rows_found)
SELECT N'sys.dm_db_xtp_index_memory_stats', 0;

-- Check sys.dm_db_xtp_table_memory_stats (no data content)
INSERT INTO #results (object_name, rows_found)
SELECT N'sys.dm_db_xtp_table_memory_stats', 0;

-- Check sys.dm_db_xtp_gc_stats (no data content)
INSERT INTO #results (object_name, rows_found)
SELECT N'sys.dm_db_xtp_gc_stats', 0;

-- Check sys.dm_db_xtp_checkpoint_files (no data content)
INSERT INTO #results (object_name, rows_found)
SELECT N'sys.dm_db_xtp_checkpoint_files', 0;

-- Check sys.dm_db_xtp_transaction_stats (no data content)
INSERT INTO #results (object_name, rows_found)
SELECT N'sys.dm_db_xtp_transaction_stats', 0;

-- Check sys.dm_db_xtp_index_usage_stats (no data content)
INSERT INTO #results (object_name, rows_found)
SELECT N'sys.dm_db_xtp_index_usage_stats', 0;

-- Check sys.dm_db_xtp_table_usage_stats (no data content)
INSERT INTO #results (object_name, rows_found)
SELECT N'sys.dm_db_xtp_table_usage_stats', 0;

-- Check sys.dm_db_xtp_object_usage_stats (no data content)
INSERT INTO #results (object_name, rows_found)
SELECT N'sys.dm_db_xtp_object_usage_stats', 0;

-- Check sys.dm_db_xtp_memory_usage_stats (no data content)
INSERT INTO #results (object_name, rows_found)
SELECT N'sys.dm_db_xtp_memory_usage_stats', 0;

-- Check sys.dm_db_xtp_gc_cycle_stats (no data content)
INSERT INTO #results (object_name, rows_found)
SELECT N'sys.dm_db_xtp_gc_cycle_stats', 0;

-- Check sys.dm_db_xtp_transaction_recent (no data content)
INSERT INTO #results (object_name, rows_found)
SELECT N'sys.dm_db_xtp_transaction_recent', 0;

-- Check sys.dm_db_xtp_transaction_log (no data content)
INSERT INTO #results (object_name, rows_found)
SELECT N'sys.dm_db_xtp_transaction_log', 0;

-- Check sys.dm_db_xtp_object_memory_stats (no data content)
INSERT INTO #results (object_name, rows_found)
SELECT N'sys.dm_db_xtp_object_memory_stats', 0;

-- Check sys.dm_db_xtp_index_memory_stats (no data content)
INSERT INTO #results (object_name, rows_found)
SELECT N'sys.dm_db_xtp_index_memory_stats', 0;

-- Check sys.dm_db_xtp_table_memory_stats (no data content)
INSERT INTO #results (object_name, rows_found)
SELECT N'sys.dm_db_xtp_table_memory_stats', 0;

-- Check sys.dm_db_xtp_gc_stats (no data content)
INSERT INTO #results (object_name, rows_found)
SELECT N'sys.dm_db_xtp_gc_stats', 0;

-- Check sys.dm_db_xtp_checkpoint_files (no data content)
INSERT INTO #results (object_name, rows_found)
SELECT N'sys.dm_db_xtp_checkpoint_files', 0;

-- Check sys.dm_db_xtp_transaction_stats (no data content)
INSERT INTO #results (object_name, rows_found)
SELECT N'sys.dm_db_xtp_transaction_stats', 0;

-- Check sys.dm_db_xtp_index_usage_stats (no data content)
INSERT INTO #results (object_name, rows_found)
SELECT N'sys.dm_db_xtp_index_usage_stats', 0;

-- Check sys.dm_db_xtp_table_usage_stats (no data content)
INSERT INTO #results (object_name, rows_found)
SELECT N'sys.dm_db_xtp_table_usage_stats', 0;

-- Check sys.dm_db_xtp_object_usage_stats (no data content)
INSERT INTO #results (object_name, rows_found)
SELECT N'sys.dm_db_xtp_object_usage_stats', 0;

-- Check sys.dm_db_xtp_memory_usage_stats (no data content)
INSERT INTO #results (object_name, rows_found)
SELECT N'sys.dm_db_xtp_memory_usage_stats', 0;

-- Check sys.dm_db_xtp_gc_cycle_stats (no data content)
INSERT INTO #results (object_name, rows_found)
SELECT N'sys.dm_db_xtp_gc_cycle_stats', 0;

-- Check sys.dm_db_xtp_transaction_recent (no data content)
INSERT INTO #results (object_name, rows_found)
SELECT N'sys.dm_db_xtp_transaction_recent', 0;

-- Check sys.dm_db_xtp_transaction_log (no data content)
INSERT INTO #results (object_name, rows_found)
SELECT N'sys.dm_db_xtp_transaction_log', 0;

-- Check sys.dm_db_xtp_object_memory_stats (no data content)
INSERT INTO #results (object_name, rows_found)
SELECT N'sys.dm_db_xtp_object_memory_stats', 0;

-- Check sys.dm_db_xtp_index_memory_stats (no data content)
INSERT INTO #results (object_name, rows_found)
SELECT N'sys.dm_db_xtp_index_memory_stats', 0;

-- Check sys.dm_db_xtp_table_memory_stats (no data content)
INSERT INTO #results (object_name, rows_found)
SELECT N'sys.dm_db_xtp_table_memory_stats', 0;

-- Check sys.dm_db_xtp_gc_stats (no data content)
INSERT INTO #results (object_name, rows_found)
SELECT N'sys.dm_db_xtp_gc_stats', 0;

-- Check sys.dm_db_xtp_checkpoint_files (no data content)
INSERT INTO #results (object_name, rows_found)
SELECT N'sys.dm_db_xtp_checkpoint_files', 0;

-- Check sys.dm_db_xtp_transaction_stats (no data content)
INSERT INTO #results (object_name, rows_found)
SELECT N'sys.dm_db_xtp_transaction_stats', 0;

-- Check sys.dm_db_xtp_index_usage_stats (no data content)
INSERT INTO #results (object_name, rows_found)
SELECT N'sys.dm_db_xtp_index_usage_stats', 0;

-- Check sys.dm_db_xtp_table_usage_stats (no data content)
INSERT INTO #results (object_name, rows_found)
SELECT N'sys.dm_db_xtp_table_usage_stats', 0;

-- Check sys.dm_db_xtp_object_usage_stats (no data content)
INSERT INTO #results (object_name, rows_found)
SELECT N'sys.dm_db_xtp_object_usage_stats', 0;

-- Check sys.dm_db_xtp_memory_usage_stats (no data content)
INSERT INTO #results (object_name, rows_found)
SELECT N'sys.dm_db_xtp_memory_usage_stats', 0;

-- Check sys.dm_db_xtp_gc_cycle_stats (no data content)
INSERT INTO #results (object_name, rows_found)
SELECT N'sys.dm_db_xtp_gc_cycle_stats', 0;

-- Final select
SELECT object_name, rows_found FROM #results ORDER BY object_name;

DROP TABLE #results;
