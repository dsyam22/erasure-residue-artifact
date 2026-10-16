DECLARE @customer_id INT = 42;
DECLARE @phone NVARCHAR(20) = '+1-555-0000042';

CREATE TABLE #results (
    object_name NVARCHAR(255),
    rows_found INT
);

-- Check current customer table (phone column should be dropped)
IF EXISTS (
    SELECT 1
    FROM sys.columns
    WHERE object_id = OBJECT_ID('dbo.customer')
      AND name = 'phone'
)
BEGIN
    INSERT INTO #results (object_name, rows_found)
    SELECT 'dbo.customer', COUNT(*)
    FROM dbo.customer
    WHERE customer_id = @customer_id
      AND phone = @phone;
END
ELSE
BEGIN
    INSERT INTO #results (object_name, rows_found)
    VALUES ('dbo.customer', 0);
END

-- Check CDC change table
IF EXISTS (
    SELECT 1
    FROM sys.tables
    WHERE name = 'dbo_customer_CT'
      AND schema_id = SCHEMA_ID('cdc')
)
BEGIN
    INSERT INTO #results (object_name, rows_found)
    SELECT 'cdc.dbo_customer_CT', COUNT(*)
    FROM cdc.dbo_customer_CT
    WHERE customer_id = @customer_id
      AND phone = @phone;
END
ELSE
BEGIN
    INSERT INTO #results (object_name, rows_found)
    VALUES ('cdc.dbo_customer_CT', 0);
END

-- Check for any temporal history tables (none expected, but checking)
IF EXISTS (
    SELECT 1
    FROM sys.tables
    WHERE temporal_type_desc = 'HISTORY_TABLE'
      AND name LIKE '%customer%'
)
BEGIN
    DECLARE @history_table NVARCHAR(255);
    DECLARE history_cursor CURSOR FOR
        SELECT QUOTENAME(SCHEMA_NAME(schema_id)) + '.' + QUOTENAME(name)
        FROM sys.tables
        WHERE temporal_type_desc = 'HISTORY_TABLE'
          AND name LIKE '%customer%';

    OPEN history_cursor;
    FETCH NEXT FROM history_cursor INTO @history_table;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        DECLARE @sql NVARCHAR(MAX);
        SET @sql = N'INSERT INTO #results (object_name, rows_found)
                     SELECT ''' + @history_table + ''', COUNT(*)
                     FROM ' + @history_table + '
                     WHERE customer_id = ' + CAST(@customer_id AS NVARCHAR) + '
                       AND phone = ''' + @phone + '''';
        EXEC sp_executesql @sql;
        FETCH NEXT FROM history_cursor INTO @history_table;
    END

    CLOSE history_cursor;
    DEALLOCATE history_cursor;
END
ELSE
BEGIN
    INSERT INTO #results (object_name, rows_found)
    VALUES ('temporal_history_customer', 0);
END

-- Check for any other tables that might contain customer phone data (downstream copies)
-- Common naming patterns
IF EXISTS (
    SELECT 1
    FROM sys.tables t
    JOIN sys.columns c ON t.object_id = c.object_id
    WHERE c.name = 'phone'
      AND (t.name LIKE '%customer%' OR t.name LIKE '%contact%' OR t.name LIKE '%profile%')
      AND t.name != 'customer'
)
BEGIN
    DECLARE @table_name NVARCHAR(255);
    DECLARE table_cursor CURSOR FOR
        SELECT QUOTENAME(SCHEMA_NAME(t.schema_id)) + '.' + QUOTENAME(t.name)
        FROM sys.tables t
        JOIN sys.columns c ON t.object_id = c.object_id
        WHERE c.name = 'phone'
          AND (t.name LIKE '%customer%' OR t.name LIKE '%contact%' OR t.name LIKE '%profile%')
          AND t.name != 'customer';

    OPEN table_cursor;
    FETCH NEXT FROM table_cursor INTO @table_name;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @sql = N'INSERT INTO #results (object_name, rows_found)
                     SELECT ''' + @table_name + ''', COUNT(*)
                     FROM ' + @table_name + '
                     WHERE customer_id = ' + CAST(@customer_id AS NVARCHAR) + '
                       AND phone = ''' + @phone + '''';
        EXEC sp_executesql @sql;
        FETCH NEXT FROM table_cursor INTO @table_name;
    END

    CLOSE table_cursor;
    DEALLOCATE table_cursor;
END
ELSE
BEGIN
    INSERT INTO #results (object_name, rows_found)
    VALUES ('downstream_copies', 0);
END

-- Return final results
SELECT object_name, rows_found
FROM #results
ORDER BY object_name;

DROP TABLE #results;
