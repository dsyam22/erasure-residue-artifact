DECLARE @db_name NVARCHAR(128) = DB_NAME();
DECLARE @sql NVARCHAR(MAX) = N'';

-- Temporary table to hold results
CREATE TABLE #results (
    object_name NVARCHAR(255),
    rows_found INT
);

-- We will check all user tables for any column that might contain the phone number
-- Since the phone column was dropped from dbo.customer, we need to check all remaining columns
-- in all tables for the exact phone number string.

DECLARE @table_schema NVARCHAR(128);
DECLARE @table_name NVARCHAR(128);
DECLARE @column_name NVARCHAR(128);
DECLARE @full_table_name NVARCHAR(255);

DECLARE table_cursor CURSOR FOR
SELECT 
    s.name AS schema_name,
    t.name AS table_name,
    c.name AS column_name
FROM sys.tables t
INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
INNER JOIN sys.columns c ON t.object_id = c.object_id
INNER JOIN sys.types ty ON c.user_type_id = ty.user_type_id
WHERE ty.name IN ('nvarchar', 'varchar', 'nchar', 'char', 'text', 'ntext', 'sysname')
  AND t.is_ms_shipped = 0
ORDER BY s.name, t.name, c.column_id;

OPEN table_cursor;
FETCH NEXT FROM table_cursor INTO @table_schema, @table_name, @column_name;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @full_table_name = QUOTENAME(@table_schema) + '.' + QUOTENAME(@table_name);
    
    SET @sql = N'INSERT INTO #results (object_name, rows_found)
                 SELECT ''' + @full_table_name + '.' + QUOTENAME(@column_name) + ''' AS object_name,
                        COUNT(*) AS rows_found
                 FROM ' + @full_table_name + '
                 WHERE ' + QUOTENAME(@column_name) + ' = ''+1-555-0000042''';
    
    BEGIN TRY
        EXEC sp_executesql @sql;
    END TRY
    BEGIN CATCH
        -- If column doesn't exist or any error, insert 0 for that object
        INSERT INTO #results (object_name, rows_found)
        VALUES (@full_table_name + '.' + QUOTENAME(@column_name), 0);
    END CATCH
    
    FETCH NEXT FROM table_cursor INTO @table_schema, @table_name, @column_name;
END

CLOSE table_cursor;
DEALLOCATE table_cursor;

-- If no tables/columns were checked, return a single row with 0
IF NOT EXISTS (SELECT 1 FROM #results)
BEGIN
    INSERT INTO #results (object_name, rows_found)
    VALUES ('(no tables found)', 0);
END

-- Return final result set
SELECT object_name, rows_found
FROM #results
ORDER BY object_name;

DROP TABLE #results;
