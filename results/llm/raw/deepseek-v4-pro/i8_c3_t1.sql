SET NOCOUNT ON;

CREATE TABLE #results (
    object_name nvarchar(500),
    rows_found bigint
);

-- Check dbo.customer table
INSERT INTO #results (object_name, rows_found)
SELECT N'dbo.customer', COUNT(*)
FROM dbo.customer
WHERE customer_id = 42
   OR full_name = N'Subject_0000042'
   OR email = N'subject42@example.invalid'
   OR phone = N'+1-555-0000042';

-- Check for CDC change tables (even though cdc_enabled=0, we still check)
IF EXISTS (SELECT 1 FROM sys.tables WHERE name LIKE '%_CT' AND is_tracked_by_cdc = 1)
BEGIN
    DECLARE @cdc_table_name nvarchar(500);
    DECLARE cdc_cursor CURSOR FOR
        SELECT QUOTENAME(s.name) + N'.' + QUOTENAME(t.name)
        FROM sys.tables t
        JOIN sys.schemas s ON t.schema_id = s.schema_id
        WHERE t.name LIKE '%_CT'
          AND t.is_tracked_by_cdc = 1;

    OPEN cdc_cursor;
    FETCH NEXT FROM cdc_cursor INTO @cdc_table_name;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        DECLARE @sql nvarchar(max);
        SET @sql = N'INSERT INTO #results (object_name, rows_found) SELECT N''' + @cdc_table_name + N''', COUNT(*) FROM ' + @cdc_table_name + N' WHERE customer_id = 42 OR full_name = N''Subject_0000042'' OR email = N''subject42@example.invalid'' OR phone = N''+1-555-0000042''';
        EXEC sp_executesql @sql;
        FETCH NEXT FROM cdc_cursor INTO @cdc_table_name;
    END;

    CLOSE cdc_cursor;
    DEALLOCATE cdc_cursor;
END

-- Check for temporal history tables
IF EXISTS (SELECT 1 FROM sys.tables WHERE temporal_type = 1)
BEGIN
    DECLARE @history_table_name nvarchar(500);
    DECLARE history_cursor CURSOR FOR
        SELECT QUOTENAME(s.name) + N'.' + QUOTENAME(t.name)
        FROM sys.tables t
        JOIN sys.schemas s ON t.schema_id = s.schema_id
        WHERE t.temporal_type = 1;

    OPEN history_cursor;
    FETCH NEXT FROM history_cursor INTO @history_table_name;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @sql = N'INSERT INTO #results (object_name, rows_found) SELECT N''' + @history_table_name + N''', COUNT(*) FROM ' + @history_table_name + N' WHERE customer_id = 42 OR full_name = N''Subject_0000042'' OR email = N''subject42@example.invalid'' OR phone = N''+1-555-0000042''';
        EXEC sp_executesql @sql;
        FETCH NEXT FROM history_cursor INTO @history_table_name;
    END;

    CLOSE history_cursor;
    DEALLOCATE history_cursor;
END

-- Check all user tables for columns matching customer_id, full_name, email, phone
-- and containing the subject's data
DECLARE @table_name nvarchar(500);
DECLARE table_cursor CURSOR FOR
    SELECT QUOTENAME(s.name) + N'.' + QUOTENAME(t.name)
    FROM sys.tables t
    JOIN sys.schemas s ON t.schema_id = s.schema_id
    WHERE t.is_ms_shipped = 0
      AND t.name NOT LIKE '%_CT'
      AND t.temporal_type = 0
      AND NOT (s.name = 'dbo' AND t.name = 'customer');

OPEN table_cursor;
FETCH NEXT FROM table_cursor INTO @table_name;

WHILE @@FETCH_STATUS = 0
BEGIN
    DECLARE @has_customer_id bit = 0,
            @has_full_name bit = 0,
            @has_email bit = 0,
            @has_phone bit = 0;

    SELECT @has_customer_id = CASE WHEN EXISTS (SELECT 1 FROM sys.columns c WHERE c.object_id = OBJECT_ID(@table_name) AND c.name = 'customer_id') THEN 1 ELSE 0 END;
    SELECT @has_full_name = CASE WHEN EXISTS (SELECT 1 FROM sys.columns c WHERE c.object_id = OBJECT_ID(@table_name) AND c.name = 'full_name') THEN 1 ELSE 0 END;
    SELECT @has_email = CASE WHEN EXISTS (SELECT 1 FROM sys.columns c WHERE c.object_id = OBJECT_ID(@table_name) AND c.name = 'email') THEN 1 ELSE 0 END;
    SELECT @has_phone = CASE WHEN EXISTS (SELECT 1 FROM sys.columns c WHERE c.object_id = OBJECT_ID(@table_name) AND c.name = 'phone') THEN 1 ELSE 0 END;

    IF @has_customer_id = 1 OR @has_full_name = 1 OR @has_email = 1 OR @has_phone = 1
    BEGIN
        DECLARE @where_clause nvarchar(max) = N'';
        IF @has_customer_id = 1
            SET @where_clause = @where_clause + N'customer_id = 42 OR ';
        IF @has_full_name = 1
            SET @where_clause = @where_clause + N'full_name = N''Subject_0000042'' OR ';
        IF @has_email = 1
            SET @where_clause = @where_clause + N'email = N''subject42@example.invalid'' OR ';
        IF @has_phone = 1
            SET @where_clause = @where_clause + N'phone = N''+1-555-0000042'' OR ';

        IF LEN(@where_clause) > 0
        BEGIN
            SET @where_clause = LEFT(@where_clause, LEN(@where_clause) - 4); -- remove trailing ' OR '
            SET @sql = N'INSERT INTO #results (object_name, rows_found) SELECT N''' + @table_name + N''', COUNT(*) FROM ' + @table_name + N' WHERE ' + @where_clause;
            EXEC sp_executesql @sql;
        END
    END

    FETCH NEXT FROM table_cursor INTO @table_name;
END;

CLOSE table_cursor;
DEALLOCATE table_cursor;

-- Return final result set
SELECT object_name, rows_found
FROM #results
ORDER BY object_name;

DROP TABLE #results;
