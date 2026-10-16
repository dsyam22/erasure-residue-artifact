SET NOCOUNT ON;

DECLARE @CustomerID int = 42;
DECLARE @OriginalPhone nvarchar(50) = '+1-555-0000042';

CREATE TABLE #Results (
    object_name nvarchar(255),
    rows_found int
);

-- Check current customer table (phone column dropped, so no phone data expected)
INSERT INTO #Results (object_name, rows_found)
SELECT 'dbo.customer', COUNT(*)
FROM dbo.customer
WHERE customer_id = @CustomerID
  AND (CAST(full_name AS nvarchar(max)) = 'Subject_0000042'
       OR CAST(email AS nvarchar(max)) = 'subject42@example.invalid');

-- Check CDC change table for the customer table
IF EXISTS (SELECT 1 FROM sys.tables WHERE name = 'dbo_customer_CT' AND schema_id = SCHEMA_ID('cdc'))
BEGIN
    INSERT INTO #Results (object_name, rows_found)
    SELECT 'cdc.dbo_customer_CT', COUNT(*)
    FROM cdc.dbo_customer_CT
    WHERE customer_id = @CustomerID
      AND phone = @OriginalPhone;
END
ELSE
BEGIN
    INSERT INTO #Results (object_name, rows_found)
    SELECT 'cdc.dbo_customer_CT', 0;
END

-- Check for any other tables that might contain a phone column with the original value
DECLARE @TableName nvarchar(255);
DECLARE @SchemaName nvarchar(128);
DECLARE @ColumnName nvarchar(128);
DECLARE @SQL nvarchar(max);

DECLARE table_cursor CURSOR FOR
SELECT s.name AS schema_name, t.name AS table_name, c.name AS column_name
FROM sys.tables t
JOIN sys.schemas s ON t.schema_id = s.schema_id
JOIN sys.columns c ON t.object_id = c.object_id
WHERE c.name LIKE '%phone%'
  AND t.name NOT IN ('customer')
  AND s.name NOT IN ('cdc');

OPEN table_cursor;
FETCH NEXT FROM table_cursor INTO @SchemaName, @TableName, @ColumnName;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @SQL = N'INSERT INTO #Results (object_name, rows_found) SELECT ''' 
               + QUOTENAME(@SchemaName) + '.' + QUOTENAME(@TableName) + ''', COUNT(*) FROM ' 
               + QUOTENAME(@SchemaName) + '.' + QUOTENAME(@TableName) 
               + N' WHERE ' + QUOTENAME(@ColumnName) + N' = @OriginalPhone';
    
    EXEC sp_executesql @SQL, N'@OriginalPhone nvarchar(50)', @OriginalPhone = @OriginalPhone;
    
    FETCH NEXT FROM table_cursor INTO @SchemaName, @TableName, @ColumnName;
END

CLOSE table_cursor;
DEALLOCATE table_cursor;

-- Check temporal history tables if any exist
IF EXISTS (SELECT 1 FROM sys.tables WHERE temporal_type = 1)
BEGIN
    DECLARE @HistorySchema nvarchar(128);
    DECLARE @HistoryTable nvarchar(255);
    DECLARE @HistoryColumn nvarchar(128);
    
    DECLARE history_cursor CURSOR FOR
    SELECT s.name AS schema_name, t.name AS table_name, c.name AS column_name
    FROM sys.tables t
    JOIN sys.schemas s ON t.schema_id = s.schema_id
    JOIN sys.columns c ON t.object_id = c.object_id
    WHERE t.temporal_type = 1
      AND c.name LIKE '%phone%';
    
    OPEN history_cursor;
    FETCH NEXT FROM history_cursor INTO @HistorySchema, @HistoryTable, @HistoryColumn;
    
    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @SQL = N'INSERT INTO #Results (object_name, rows_found) SELECT ''' 
                   + QUOTENAME(@HistorySchema) + '.' + QUOTENAME(@HistoryTable) + ''', COUNT(*) FROM ' 
                   + QUOTENAME(@HistorySchema) + '.' + QUOTENAME(@HistoryTable) 
                   + N' WHERE ' + QUOTENAME(@HistoryColumn) + N' = @OriginalPhone';
        
        EXEC sp_executesql @SQL, N'@OriginalPhone nvarchar(50)', @OriginalPhone = @OriginalPhone;
        
        FETCH NEXT FROM history_cursor INTO @HistorySchema, @HistoryTable, @HistoryColumn;
    END
    
    CLOSE history_cursor;
    DEALLOCATE history_cursor;
END

-- Return final result set
SELECT object_name, rows_found
FROM #Results
ORDER BY object_name;

DROP TABLE #Results;
