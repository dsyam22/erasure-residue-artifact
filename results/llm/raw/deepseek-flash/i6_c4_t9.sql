SELECT object_name, rows_found
FROM (
    SELECT 'cdc.dbo_customer_CT' AS object_name,
           COUNT(*) AS rows_found
    FROM cdc.dbo_customer_CT
    WHERE phone = '+1-555-0000042'
       OR phone LIKE '%555-0000042%'
       OR phone LIKE '%5550000042%'

    UNION ALL

    SELECT 'cdc.captured_columns' AS object_name,
           COUNT(*) AS rows_found
    FROM cdc.captured_columns
    WHERE column_name = 'phone'

    UNION ALL

    SELECT 'cdc.ddl_history' AS object_name,
           COUNT(*) AS rows_found
    FROM cdc.ddl_history
    WHERE ddl_command LIKE '%phone%'
       OR ddl_command LIKE '%555-0000042%'
       OR ddl_command LIKE '%5550000042%'

    UNION ALL

    SELECT 'cdc.index_columns' AS object_name,
           COUNT(*) AS rows_found
    FROM cdc.index_columns
    WHERE column_name = 'phone'

    UNION ALL

    SELECT 'cdc.change_tables' AS object_name,
           COUNT(*) AS rows_found
    FROM cdc.change_tables
    WHERE capture_instance LIKE '%phone%'

    UNION ALL

    SELECT 'cdc.lsn_time_mapping' AS object_name,
           COUNT(*) AS rows_found
    FROM cdc.lsn_time_mapping
    WHERE CAST(tran_id AS nvarchar(max)) LIKE '%555-0000042%'
       OR CAST(tran_id AS nvarchar(max)) LIKE '%5550000042%'

    UNION ALL

    SELECT 'cdc.systranschemas' AS object_name,
           COUNT(*) AS rows_found
    FROM cdc.systranschemas
    WHERE CAST(tabid AS nvarchar(max)) LIKE '%555-0000042%'

    UNION ALL

    SELECT 'dbo.customer' AS object_name,
           COUNT(*) AS rows_found
    FROM dbo.customer
    WHERE full_name = 'Subject_0000042'
      AND email = 'subject42@example.invalid'
      AND CAST(customer_id AS nvarchar(max)) LIKE '%555-0000042%'

    UNION ALL

    SELECT 'dbo.systranschemas' AS object_name,
           COUNT(*) AS rows_found
    FROM dbo.systranschemas
    WHERE CAST(tabid AS nvarchar(max)) LIKE '%555-0000042%'
) AS checks
ORDER BY object_name;
