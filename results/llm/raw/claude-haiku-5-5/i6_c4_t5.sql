SELECT 'dbo.customer' AS object_name,
       0 AS rows_found  -- phone column was dropped; no phone value can be stored here
UNION ALL
SELECT 'cdc.dbo_customer_CT',
       (SELECT COUNT(*) FROM cdc.dbo_customer_CT
        WHERE customer_id = 42 AND phone = N'+1-555-0000042')
UNION ALL
SELECT 'cdc.ddl_history',
       (SELECT COUNT(*) FROM cdc.ddl_history
        WHERE ddl_command LIKE N'%+1-555-0000042%')
UNION ALL
SELECT 'cdc.captured_columns', 0   -- metadata only: column names/types, no row values
UNION ALL
SELECT 'cdc.change_tables', 0      -- metadata only
UNION ALL
SELECT 'cdc.index_columns', 0      -- metadata only
UNION ALL
SELECT 'cdc.lsn_time_mapping', 0   -- LSN/time values only, no personal data
UNION ALL
SELECT 'dbo.systranschemas', 0     -- replication metadata only, no personal data;
ORDER BY object_name;
