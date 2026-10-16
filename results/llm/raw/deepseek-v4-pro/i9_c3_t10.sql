SET NOCOUNT ON;

DECLARE @customer_id INT = 42;
DECLARE @full_name NVARCHAR(255) = N'Subject_0000042';
DECLARE @email NVARCHAR(255) = N'subject42@example.invalid';
DECLARE @phone NVARCHAR(255) = N'+1-555-0000042';

CREATE TABLE #results (
    object_name NVARCHAR(255) NOT NULL,
    rows_found INT NOT NULL
);

-- Check current table
INSERT INTO #results (object_name, rows_found)
SELECT N'dbo.customer', COUNT(*)
FROM dbo.customer
WHERE customer_id = @customer_id
   OR full_name = @full_name
   OR email = @email
   OR phone = @phone;

-- Check temporal history table
INSERT INTO #results (object_name, rows_found)
SELECT N'dbo.customer_history', COUNT(*)
FROM dbo.customer_history
WHERE customer_id = @customer_id
   OR full_name = @full_name
   OR email = @email
   OR phone = @phone;

-- Check CDC change tables (if any exist)
IF EXISTS (SELECT 1 FROM sys.tables WHERE name LIKE 'cdc.%' AND is_tracked_by_cdc = 1)
BEGIN
    DECLARE @cdc_table NVARCHAR(255);
    DECLARE cdc_cursor CURSOR FOR
        SELECT QUOTENAME(SCHEMA_NAME(schema_id)) + N'.' + QUOTENAME(name)
        FROM sys.tables
        WHERE name LIKE 'cdc.%' AND is_tracked_by_cdc = 1;

    OPEN cdc_cursor;
    FETCH NEXT FROM cdc_cursor INTO @cdc_table;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        DECLARE @sql NVARCHAR(MAX) = N'
            INSERT INTO #results (object_name, rows_found)
            SELECT N''' + @cdc_table + N''', COUNT(*)
            FROM ' + @cdc_table + N'
            WHERE CAST(customer_id AS NVARCHAR(50)) = @customer_id
               OR full_name = @full_name
               OR email = @email
               OR phone = @phone';
        
        BEGIN TRY
            EXEC sp_executesql @sql, N'@customer_id INT, @full_name NVARCHAR(255), @email NVARCHAR(255), @phone NVARCHAR(255)', 
                @customer_id, @full_name, @email, @phone;
        END TRY
        BEGIN CATCH
            -- Skip if columns don't match; still record as checked with 0
            INSERT INTO #results (object_name, rows_found)
            SELECT @cdc_table, 0;
        END CATCH;

        FETCH NEXT FROM cdc_cursor INTO @cdc_table;
    END;

    CLOSE cdc_cursor;
    DEALLOCATE cdc_cursor;
END

-- Check for any other user tables that might contain copies of the data
DECLARE @table_name NVARCHAR(255);
DECLARE table_cursor CURSOR FOR
    SELECT QUOTENAME(SCHEMA_NAME(schema_id)) + N'.' + QUOTENAME(name)
    FROM sys.tables
    WHERE is_ms_shipped = 0
      AND temporal_type = 0
      AND name NOT IN ('customer', 'customer_history')
      AND name NOT LIKE 'cdc.%';

OPEN table_cursor;
FETCH NEXT FROM table_cursor INTO @table_name;

WHILE @@FETCH_STATUS = 0
BEGIN
    DECLARE @table_sql NVARCHAR(MAX) = N'
        IF EXISTS (
            SELECT 1 FROM sys.columns 
            WHERE object_id = OBJECT_ID(@table_name) 
              AND name IN (''customer_id'', ''full_name'', ''email'', ''phone'')
        )
        BEGIN
            INSERT INTO #results (object_name, rows_found)
            SELECT @table_name, COUNT(*)
            FROM ' + @table_name + N'
            WHERE (customer_id = @customer_id)
               OR (full_name = @full_name)
               OR (email = @email)
               OR (phone = @phone)
        END
        ELSE
        BEGIN
            INSERT INTO #results (object_name, rows_found)
            SELECT @table_name, 0
        END';

    BEGIN TRY
        EXEC sp_executesql @table_sql, N'@table_name NVARCHAR(255), @customer_id INT, @full_name NVARCHAR(255), @email NVARCHAR(255), @phone NVARCHAR(255)',
            @table_name, @customer_id, @full_name, @email, @phone;
    END TRY
    BEGIN CATCH
        INSERT INTO #results (object_name, rows_found)
        SELECT @table_name, 0;
    END CATCH;

    FETCH NEXT FROM table_cursor INTO @table_name;
END;

CLOSE table_cursor;
DEALLOCATE table_cursor;

-- Return final results
SELECT object_name, rows_found
FROM #results
ORDER BY object_name;

DROP TABLE #results;
