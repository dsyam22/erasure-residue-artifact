SET NOCOUNT ON;

DECLARE @customer_id INT = 42;
DECLARE @full_name NVARCHAR(255) = N'Subject_0000042';
DECLARE @email NVARCHAR(255) = N'subject42@example.invalid';
DECLARE @phone NVARCHAR(255) = N'+1-555-0000042';

CREATE TABLE #results (
    object_name NVARCHAR(255),
    rows_found INT
);

-- Check dbo.customer
INSERT INTO #results (object_name, rows_found)
SELECT 
    N'dbo.customer',
    COUNT(*)
FROM dbo.customer
WHERE customer_id = @customer_id
   OR full_name = @full_name
   OR email = @email
   OR phone = @phone;

-- Check reporting.customer_replica
INSERT INTO #results (object_name, rows_found)
SELECT 
    N'reporting.customer_replica',
    COUNT(*)
FROM reporting.customer_replica
WHERE customer_id = @customer_id
   OR full_name = @full_name
   OR email = @email
   OR phone = @phone;

-- Check for CDC change tables (even though cdc_enabled=0, we still verify)
IF EXISTS (SELECT 1 FROM sys.tables WHERE name = 'customer' AND is_tracked_by_cdc = 1)
BEGIN
    DECLARE @cdc_capture_instance NVARCHAR(255);
    SELECT @cdc_capture_instance = capture_instance
    FROM cdc.change_tables
    WHERE source_object_id = OBJECT_ID('dbo.customer');

    IF @cdc_capture_instance IS NOT NULL
    BEGIN
        DECLARE @cdc_sql NVARCHAR(MAX);
        SET @cdc_sql = N'
            INSERT INTO #results (object_name, rows_found)
            SELECT 
                N''cdc.' + QUOTENAME(@cdc_capture_instance) + N'_CT'',
                COUNT(*)
            FROM cdc.' + QUOTENAME(@cdc_capture_instance) + N'_CT
            WHERE customer_id = @customer_id
               OR full_name = @full_name
               OR email = @email
               OR phone = @phone';
        EXEC sp_executesql @cdc_sql, N'@customer_id INT, @full_name NVARCHAR(255), @email NVARCHAR(255), @phone NVARCHAR(255)',
                           @customer_id, @full_name, @email, @phone;
    END
END

-- Check for temporal history tables (even though temporal_type=NON_TEMPORAL_TABLE, we still verify)
IF EXISTS (
    SELECT 1 
    FROM sys.tables t
    WHERE t.name = 'customer' 
      AND t.temporal_type = 2
)
BEGIN
    DECLARE @history_table_name NVARCHAR(255);
    SELECT @history_table_name = OBJECT_NAME(history_table_id)
    FROM sys.tables
    WHERE name = 'customer' AND temporal_type = 2;

    IF @history_table_name IS NOT NULL
    BEGIN
        DECLARE @history_sql NVARCHAR(MAX);
        SET @history_sql = N'
            INSERT INTO #results (object_name, rows_found)
            SELECT 
                N''dbo.' + QUOTENAME(@history_table_name) + N''',
                COUNT(*)
            FROM dbo.' + QUOTENAME(@history_table_name) + N'
            WHERE customer_id = @customer_id
               OR full_name = @full_name
               OR email = @email
               OR phone = @phone';
        EXEC sp_executesql @history_sql, N'@customer_id INT, @full_name NVARCHAR(255), @email NVARCHAR(255), @phone NVARCHAR(255)',
                           @customer_id, @full_name, @email, @phone;
    END
END

-- Ensure at least one row per checked object is returned, even if not inserted above
IF NOT EXISTS (SELECT 1 FROM #results WHERE object_name = N'dbo.customer')
    INSERT INTO #results VALUES (N'dbo.customer', 0);
IF NOT EXISTS (SELECT 1 FROM #results WHERE object_name = N'reporting.customer_replica')
    INSERT INTO #results VALUES (N'reporting.customer_replica', 0);

-- Return final result set
SELECT object_name, rows_found
FROM #results
ORDER BY object_name;

DROP TABLE #results;
