DECLARE @customer_id int = 42;
DECLARE @full_name nvarchar(255) = N'Subject_0000042';
DECLARE @email nvarchar(255) = N'subject42@example.invalid';
DECLARE @phone nvarchar(255) = N'+1-555-0000042';

CREATE TABLE #results (
    object_name nvarchar(255),
    rows_found int
);

-- Check the base table
INSERT INTO #results (object_name, rows_found)
SELECT N'dbo.customer', COUNT(*)
FROM dbo.customer
WHERE customer_id = @customer_id
   OR full_name = @full_name
   OR email = @email
   OR phone = @phone;

-- Check CDC change table
IF EXISTS (SELECT 1 FROM sys.tables WHERE name = 'dbo_customer_CT' AND schema_id = SCHEMA_ID('cdc'))
BEGIN
    INSERT INTO #results (object_name, rows_found)
    SELECT N'cdc.dbo_customer_CT', COUNT(*)
    FROM cdc.dbo_customer_CT
    WHERE customer_id = @customer_id
       OR full_name = @full_name
       OR email = @email
       OR phone = @phone;
END
ELSE
BEGIN
    INSERT INTO #results (object_name, rows_found)
    SELECT N'cdc.dbo_customer_CT', 0;
END

-- Check for temporal history table (if any)
IF EXISTS (SELECT 1 FROM sys.tables WHERE name LIKE '%customer%history%' OR temporal_type_desc = 'HISTORY_TABLE')
BEGIN
    DECLARE @history_table nvarchar(255);
    SELECT TOP 1 @history_table = QUOTENAME(SCHEMA_NAME(schema_id)) + '.' + QUOTENAME(name)
    FROM sys.tables
    WHERE temporal_type_desc = 'HISTORY_TABLE'
      AND object_id IN (
          SELECT object_id FROM sys.tables WHERE name = 'customer'
      );

    IF @history_table IS NOT NULL
    BEGIN
        DECLARE @sql nvarchar(max) = N'SELECT @cnt = COUNT(*) FROM ' + @history_table + 
            N' WHERE customer_id = @cid OR full_name = @fn OR email = @em OR phone = @ph';
        DECLARE @cnt int = 0;
        EXEC sp_executesql @sql, N'@cid int, @fn nvarchar(255), @em nvarchar(255), @ph nvarchar(255), @cnt int OUTPUT',
            @cid = @customer_id, @fn = @full_name, @em = @email, @ph = @phone, @cnt = @cnt OUTPUT;
        INSERT INTO #results (object_name, rows_found)
        SELECT @history_table, @cnt;
    END
    ELSE
    BEGIN
        INSERT INTO #results (object_name, rows_found)
        SELECT N'<temporal_history_table>', 0;
    END
END
ELSE
BEGIN
    INSERT INTO #results (object_name, rows_found)
    SELECT N'<temporal_history_table>', 0;
END

-- Check for any other tables that might contain copies (common patterns: audit, backup, log, archive)
IF EXISTS (SELECT 1 FROM sys.tables WHERE name IN ('customer_audit', 'customer_backup', 'customer_archive', 'customer_log'))
BEGIN
    DECLARE @table_name nvarchar(255);
    DECLARE @schema_name nvarchar(255);
    DECLARE @full_name_obj nvarchar(255);
    DECLARE table_cursor CURSOR FOR
        SELECT SCHEMA_NAME(schema_id), name
        FROM sys.tables
        WHERE name IN ('customer_audit', 'customer_backup', 'customer_archive', 'customer_log');

    OPEN table_cursor;
    FETCH NEXT FROM table_cursor INTO @schema_name, @table_name;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @full_name_obj = QUOTENAME(@schema_name) + '.' + QUOTENAME(@table_name);
        SET @sql = N'SELECT @cnt = COUNT(*) FROM ' + @full_name_obj + 
            N' WHERE customer_id = @cid OR full_name = @fn OR email = @em OR phone = @ph';
        SET @cnt = 0;
        EXEC sp_executesql @sql, N'@cid int, @fn nvarchar(255), @em nvarchar(255), @ph nvarchar(255), @cnt int OUTPUT',
            @cid = @customer_id, @fn = @full_name, @em = @email, @ph = @phone, @cnt = @cnt OUTPUT;
        INSERT INTO #results (object_name, rows_found)
        SELECT @full_name_obj, @cnt;

        FETCH NEXT FROM table_cursor INTO @schema_name, @table_name;
    END

    CLOSE table_cursor;
    DEALLOCATE table_cursor;
END
ELSE
BEGIN
    INSERT INTO #results (object_name, rows_found)
    SELECT N'<other_copies>', 0;
END

-- Return the final result set
SELECT object_name, rows_found
FROM #results
ORDER BY object_name;

DROP TABLE #results;
