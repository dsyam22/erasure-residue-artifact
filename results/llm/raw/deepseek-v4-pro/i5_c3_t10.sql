SET NOCOUNT ON;

DECLARE @results TABLE (object_name nvarchar(255), rows_found int);

-- Check dbo.customer
INSERT INTO @results (object_name, rows_found)
SELECT 'dbo.customer', COUNT(*)
FROM dbo.customer
WHERE customer_id = 42
  AND full_name = N'Subject_0000042'
  AND email = N'subject42@example.invalid'
  AND phone = N'+1-555-0000042';

-- Check dbo.customer_history
INSERT INTO @results (object_name, rows_found)
SELECT 'dbo.customer_history', COUNT(*)
FROM dbo.customer_history
WHERE customer_id = 42
  AND full_name = N'Subject_0000042'
  AND email = N'subject42@example.invalid'
  AND phone = N'+1-555-0000042';

-- Check system-versioned temporal history table via sys.tables metadata (if exists)
IF EXISTS (
    SELECT 1
    FROM sys.tables t
    WHERE t.name = 'customer_history'
      AND t.temporal_type = 1  -- HISTORY_TABLE
)
BEGIN
    -- Already checked above, but ensure we don't duplicate
END

-- Check change data capture (CDC) change tables if CDC is enabled
IF EXISTS (
    SELECT 1
    FROM sys.change_tracking_tables
    WHERE object_id = OBJECT_ID('dbo.customer')
)
BEGIN
    -- Change Tracking does not store historical data, only version numbers.
    -- No row-level data to inspect.
END

IF EXISTS (
    SELECT 1
    FROM sys.tables t
    WHERE t.name LIKE '%customer%'
      AND t.is_tracked_by_cdc = 1
)
BEGIN
    -- CDC capture instance tables: cdc.<capture_instance>_CT
    DECLARE @cdc_table_name nvarchar(255);
    DECLARE cdc_cursor CURSOR FOR
        SELECT 'cdc.' + ct.capture_instance + '_CT'
        FROM cdc.change_tables ct
        WHERE ct.source_object_id = OBJECT_ID('dbo.customer');

    OPEN cdc_cursor;
    FETCH NEXT FROM cdc_cursor INTO @cdc_table_name;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        DECLARE @sql nvarchar(max) = N'
            INSERT INTO @results (object_name, rows_found)
            SELECT @cdc_table_name, COUNT(*)
            FROM ' + QUOTENAME(@cdc_table_name) + N'
            WHERE customer_id = 42
              AND full_name = N''Subject_0000042''
              AND email = N''subject42@example.invalid''
              AND phone = N''+1-555-0000042'';';

        EXEC sp_executesql @sql, N'@cdc_table_name nvarchar(255)', @cdc_table_name = @cdc_table_name;

        FETCH NEXT FROM cdc_cursor INTO @cdc_table_name;
    END;

    CLOSE cdc_cursor;
    DEALLOCATE cdc_cursor;
END

-- Return final results
SELECT object_name, rows_found
FROM @results
ORDER BY object_name;
