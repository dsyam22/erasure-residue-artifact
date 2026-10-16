SET NOCOUNT ON;

CREATE TABLE #Results (
    object_name nvarchar(255),
    rows_found int
);

-- Check the main customer table
INSERT INTO #Results (object_name, rows_found)
SELECT 
    N'dbo.customer',
    COUNT(*)
FROM dbo.customer
WHERE customer_id = 42
   OR full_name = N'Subject_0000042'
   OR email = N'subject42@example.invalid'
   OR phone = N'+1-555-0000042';

-- Check for CDC change tables (if CDC is enabled at database level)
IF EXISTS (SELECT 1 FROM sys.change_tracking_databases WHERE database_id = DB_ID())
BEGIN
    DECLARE @cdc_table nvarchar(255);
    DECLARE cdc_cursor CURSOR FOR
        SELECT s.name + N'.' + t.name
        FROM sys.tables t
        JOIN sys.schemas s ON t.schema_id = s.schema_id
        WHERE t.is_tracked_by_cdc = 1;

    OPEN cdc_cursor;
    FETCH NEXT FROM cdc_cursor INTO @cdc_table;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        DECLARE @sql nvarchar(max);
        SET @sql = N'INSERT INTO #Results (object_name, rows_found)
                     SELECT N''' + @cdc_table + N'_CT'', COUNT(*)
                     FROM cdc.' + QUOTENAME(REPLACE(REPLACE(@cdc_table, N'[', N''), N']', N'') + N'_CT') + N'
                     WHERE customer_id = 42
                        OR full_name = N''Subject_0000042''
                        OR email = N''subject42@example.invalid''
                        OR phone = N''+1-555-0000042'';';
        BEGIN TRY
            EXEC sp_executesql @sql;
        END TRY
        BEGIN CATCH
            -- Ignore errors if CDC table doesn't exist or columns mismatch
        END CATCH;

        FETCH NEXT FROM cdc_cursor INTO @cdc_table;
    END;

    CLOSE cdc_cursor;
    DEALLOCATE cdc_cursor;
END

-- Check for temporal history tables
DECLARE @temporal_table nvarchar(255);
DECLARE temporal_cursor CURSOR FOR
    SELECT s.name + N'.' + t.name
    FROM sys.tables t
    JOIN sys.schemas s ON t.schema_id = s.schema_id
    WHERE t.temporal_type = 1;  -- SYSTEM_VERSIONED_TEMPORAL_TABLE

OPEN temporal_cursor;
FETCH NEXT FROM temporal_cursor INTO @temporal_table;

WHILE @@FETCH_STATUS = 0
BEGIN
    DECLARE @history_table nvarchar(255);
    DECLARE @temporal_sql nvarchar(max);
    
    SELECT @history_table = s.name + N'.' + h.name
    FROM sys.tables t
    JOIN sys.schemas s ON t.schema_id = s.schema_id
    JOIN sys.tables h ON t.history_table_id = h.object_id
    WHERE s.name + N'.' + t.name = @temporal_table;

    SET @temporal_sql = N'INSERT INTO #Results (object_name, rows_found)
                         SELECT N''' + @history_table + N''', COUNT(*)
                         FROM ' + @history_table + N'
                         WHERE customer_id = 42
                            OR full_name = N''Subject_0000042''
                            OR email = N''subject42@example.invalid''
                            OR phone = N''+1-555-0000042'';';
    BEGIN TRY
        EXEC sp_executesql @temporal_sql;
    END TRY
    BEGIN CATCH
        -- Ignore errors if history table doesn't exist or columns mismatch
    END CATCH;

    FETCH NEXT FROM temporal_cursor INTO @temporal_table;
END;

CLOSE temporal_cursor;
DEALLOCATE temporal_cursor;

-- Return final results
SELECT object_name, rows_found
FROM #Results
ORDER BY object_name;

DROP TABLE #Results;
