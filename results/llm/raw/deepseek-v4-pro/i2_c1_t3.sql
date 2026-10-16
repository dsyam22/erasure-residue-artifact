SET NOCOUNT ON;

DECLARE @customer_id int = 42;
DECLARE @full_name nvarchar(255) = N'Subject_0000042';
DECLARE @email nvarchar(255) = N'subject42@example.invalid';
DECLARE @phone nvarchar(50) = N'+1-555-0000042';

CREATE TABLE #results (
    object_name nvarchar(255),
    rows_found int
);

-- Check dbo.customer
INSERT INTO #results (object_name, rows_found)
SELECT 
    N'dbo.customer',
    COUNT(*)
FROM dbo.customer
WHERE customer_id = @customer_id
   OR full_name = @full_name
   OR email = @email
   OR phone = @phone;

-- Check all user tables for columns that might contain the personal data
DECLARE @table_schema nvarchar(128);
DECLARE @table_name nvarchar(128);
DECLARE @column_name nvarchar(128);
DECLARE @sql nvarchar(max);

DECLARE table_cursor CURSOR FOR
SELECT 
    s.name AS table_schema,
    t.name AS table_name,
    c.name AS column_name
FROM sys.tables t
JOIN sys.schemas s ON t.schema_id = s.schema_id
JOIN sys.columns c ON t.object_id = c.object_id
JOIN sys.types ty ON c.user_type_id = ty.user_type_id
WHERE ty.name IN ('nvarchar', 'varchar', 'nchar', 'char', 'ntext', 'text')
  AND NOT (s.name = 'dbo' AND t.name = 'customer') -- already checked
ORDER BY s.name, t.name, c.name;

DECLARE @current_table nvarchar(255);
DECLARE @last_table nvarchar(255) = N'';

OPEN table_cursor;
FETCH NEXT FROM table_cursor INTO @table_schema, @table_name, @column_name;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @current_table = QUOTENAME(@table_schema) + N'.' + QUOTENAME(@table_name);

    IF @current_table <> @last_table
    BEGIN
        -- First time seeing this table; check if we already have a row for it
        IF NOT EXISTS (SELECT 1 FROM #results WHERE object_name = @current_table)
        BEGIN
            INSERT INTO #results (object_name, rows_found)
            SELECT @current_table, 0;
        END
        SET @last_table = @current_table;
    END

    SET @sql = N'UPDATE #results SET rows_found = rows_found + (SELECT COUNT(*) FROM ' + @current_table + 
               N' WHERE ' + QUOTENAME(@column_name) + N' IN (@full_name, @email, @phone) OR ' +
               QUOTENAME(@column_name) + N' = CAST(@customer_id AS nvarchar(50))) ' +
               N'WHERE object_name = @current_table';

    EXEC sp_executesql @sql, 
         N'@full_name nvarchar(255), @email nvarchar(255), @phone nvarchar(50), @customer_id int, @current_table nvarchar(255)',
         @full_name, @email, @phone, @customer_id, @current_table;

    FETCH NEXT FROM table_cursor INTO @table_schema, @table_name, @column_name;
END

CLOSE table_cursor;
DEALLOCATE table_cursor;

-- Ensure dbo.customer is present even if it has 0 rows
IF NOT EXISTS (SELECT 1 FROM #results WHERE object_name = N'dbo.customer')
    INSERT INTO #results (object_name, rows_found) VALUES (N'dbo.customer', 0);

-- Return final result set
SELECT object_name, rows_found
FROM #results
ORDER BY object_name;

DROP TABLE #results;
