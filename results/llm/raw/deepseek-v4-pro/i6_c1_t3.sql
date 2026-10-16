DECLARE @SchemaName sysname = N'dbo';
DECLARE @TableName sysname = N'customer';
DECLARE @CustomerId int = 42;
DECLARE @PhonePattern nvarchar(50) = N'+1-555-0000042';

-- Temporary table to hold results
CREATE TABLE #Results (
    object_name nvarchar(257),
    rows_found int
);

-- Check dbo.customer for the phone number (column no longer exists, so we check if any column contains the pattern)
DECLARE @sql nvarchar(max);
DECLARE @ColumnList nvarchar(max) = N'';

-- Build list of columns in dbo.customer
SELECT @ColumnList = @ColumnList + QUOTENAME(c.name) + N', '
FROM sys.columns c
WHERE c.object_id = OBJECT_ID(@SchemaName + N'.' + @TableName)
  AND c.system_type_id IN (167, 175, 231, 239, 241) -- char, nchar, varchar, nvarchar, xml
ORDER BY c.column_id;

IF LEN(@ColumnList) > 0
BEGIN
    SET @ColumnList = LEFT(@ColumnList, LEN(@ColumnList) - 1);
    SET @sql = N'
        INSERT INTO #Results (object_name, rows_found)
        SELECT @SchemaName + N''.'' + @TableName, COUNT(*)
        FROM ' + QUOTENAME(@SchemaName) + N'.' + QUOTENAME(@TableName) + N'
        WHERE customer_id = @CustomerId
          AND (' + @ColumnList + N') LIKE N''%'' + @PhonePattern + N''%''';
    EXEC sp_executesql @sql, N'@SchemaName sysname, @TableName sysname, @CustomerId int, @PhonePattern nvarchar(50)', 
                       @SchemaName, @TableName, @CustomerId, @PhonePattern;
END
ELSE
BEGIN
    INSERT INTO #Results (object_name, rows_found)
    SELECT @SchemaName + N'.' + @TableName, 0;
END

-- Check all other tables in the database for any column containing the phone number
DECLARE @CurrentSchema sysname, @CurrentTable sysname;
DECLARE table_cursor CURSOR FOR
SELECT s.name, t.name
FROM sys.tables t
JOIN sys.schemas s ON t.schema_id = s.schema_id
WHERE NOT (s.name = @SchemaName AND t.name = @TableName);

OPEN table_cursor;
FETCH NEXT FROM table_cursor INTO @CurrentSchema, @CurrentTable;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @ColumnList = N'';
    SELECT @ColumnList = @ColumnList + QUOTENAME(c.name) + N', '
    FROM sys.columns c
    WHERE c.object_id = OBJECT_ID(@CurrentSchema + N'.' + @CurrentTable)
      AND c.system_type_id IN (167, 175, 231, 239, 241)
    ORDER BY c.column_id;

    IF LEN(@ColumnList) > 0
    BEGIN
        SET @ColumnList = LEFT(@ColumnList, LEN(@ColumnList) - 1);
        SET @sql = N'
            INSERT INTO #Results (object_name, rows_found)
            SELECT @CurrentSchema + N''.'' + @CurrentTable, COUNT(*)
            FROM ' + QUOTENAME(@CurrentSchema) + N'.' + QUOTENAME(@CurrentTable) + N'
            WHERE (' + @ColumnList + N') LIKE N''%'' + @PhonePattern + N''%''';
        EXEC sp_executesql @sql, N'@CurrentSchema sysname, @CurrentTable sysname, @PhonePattern nvarchar(50)', 
                           @CurrentSchema, @CurrentTable, @PhonePattern;
    END
    ELSE
    BEGIN
        INSERT INTO #Results (object_name, rows_found)
        SELECT @CurrentSchema + N'.' + @CurrentTable, 0;
    END

    FETCH NEXT FROM table_cursor INTO @CurrentSchema, @CurrentTable;
END

CLOSE table_cursor;
DEALLOCATE table_cursor;

-- Return final results
SELECT object_name, rows_found
FROM #Results
ORDER BY object_name;

DROP TABLE #Results;
