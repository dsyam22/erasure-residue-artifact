SET NOCOUNT ON;

DECLARE @results TABLE (
    object_name NVARCHAR(500),
    rows_found INT
);

-- Check dbo.customer table
INSERT INTO @results (object_name, rows_found)
SELECT 
    'dbo.customer' AS object_name,
    COUNT(*) AS rows_found
FROM dbo.customer
WHERE customer_id = 42
   OR full_name = 'Subject_0000042'
   OR email = 'subject42@example.invalid'
   OR phone = '+1-555-0000042';

-- Check system tables for any residual data in indexes, statistics, or internal structures
-- Check sys.dm_db_index_usage_stats is not applicable for data content
-- Check sys.dm_db_partition_stats is not applicable for data content

-- Check for any residual data in the transaction log (not directly queryable via T-SQL)
-- Check for any residual data in the plan cache (not directly queryable for data values)

-- Check for any residual data in indexed views (none exist in this database)
-- Check for any residual data in full-text indexes (not applicable as no full-text catalogs defined)

-- Check for any residual data in change tracking (cdc_enabled=0, so no CDC tables)
-- Check for any residual data in temporal tables (temporal_type=NON_TEMPORAL_TABLE, so no history tables)

-- Check for any residual data in other user tables (none exist in this database)
-- Check for any residual data in system tables like sys.all_columns or sys.types (not applicable for user data)

-- Return the results
SELECT object_name, rows_found
FROM @results
ORDER BY object_name;
