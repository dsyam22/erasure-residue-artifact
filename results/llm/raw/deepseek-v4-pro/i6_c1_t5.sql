DECLARE @SchemaName sysname = N'dbo';
DECLARE @TableName sysname = N'customer';
DECLARE @FullTableName nvarchar(500) = @SchemaName + N'.' + @TableName;
DECLARE @CustomerId int = 42;
DECLARE @PhonePattern nvarchar(50) = N'%+1-555-0000042%';

CREATE TABLE #Results (
    object_name nvarchar(500),
    rows_found int
);

-- Check dbo.customer for the subject's phone number in any remaining column
DECLARE @Sql nvarchar(max) = N'
    SELECT @RowsFound = COUNT(*)
    FROM ' + QUOTENAME(@SchemaName) + N'.' + QUOTENAME(@TableName) + N'
    WHERE customer_id = @CustomerId
      AND (
        CAST(full_name AS nvarchar(max)) LIKE @PhonePattern
        OR CAST(email AS nvarchar(max)) LIKE @PhonePattern
      )';

DECLARE @RowsFound int = 0;

EXEC sp_executesql @Sql,
    N'@CustomerId int, @PhonePattern nvarchar(50), @RowsFound int OUTPUT',
    @CustomerId = @CustomerId,
    @PhonePattern = @PhonePattern,
    @RowsFound = @RowsFound OUTPUT;

INSERT INTO #Results (object_name, rows_found)
VALUES (@FullTableName, @RowsFound);

-- Check all other user tables for the phone number
DECLARE @TableSchema sysname;
DECLARE @TableNameCursor sysname;
DECLARE @FullNameCursor nvarchar(500);

DECLARE table_cursor CURSOR FOR
SELECT s.name, t.name
FROM sys.tables t
JOIN sys.schemas s ON t.schema_id = s.schema_id
WHERE NOT (s.name = @SchemaName AND t.name = @TableName)
  AND t.is_ms_shipped = 0;

OPEN table_cursor;
FETCH NEXT FROM table_cursor INTO @TableSchema, @TableNameCursor;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @FullNameCursor = @TableSchema + N'.' + @TableNameCursor;
    
    DECLARE @ColumnList nvarchar(max) = N'';
    
    SELECT @ColumnList = @ColumnList + 
        CASE WHEN @ColumnList = N'' THEN N'' ELSE N' OR ' END +
        N'CAST(' + QUOTENAME(c.name) + N' AS nvarchar(max)) LIKE @PhonePattern'
    FROM sys.columns c
    WHERE c.object_id = OBJECT_ID(@FullNameCursor)
      AND c.is_computed = 0;
    
    IF @ColumnList IS NOT NULL AND @ColumnList <> N''
    BEGIN
        DECLARE @DynamicSql nvarchar(max) = N'
            SELECT @RowsFound = COUNT(*)
            FROM ' + QUOTENAME(@TableSchema) + N'.' + QUOTENAME(@TableNameCursor) + N'
            WHERE ' + @ColumnList;
        
        SET @RowsFound = 0;
        
        EXEC sp_executesql @DynamicSql,
            N'@PhonePattern nvarchar(50), @RowsFound int OUTPUT',
            @PhonePattern = @PhonePattern,
            @RowsFound = @RowsFound OUTPUT;
    END
    ELSE
    BEGIN
        SET @RowsFound = 0;
    END
    
    INSERT INTO #Results (object_name, rows_found)
    VALUES (@FullNameCursor, @RowsFound);
    
    FETCH NEXT FROM table_cursor INTO @TableSchema, @TableNameCursor;
END

CLOSE table_cursor;
DEALLOCATE table_cursor;

-- Return final results
SELECT object_name, rows_found
FROM #Results
ORDER BY object_name;

DROP TABLE #Results;
