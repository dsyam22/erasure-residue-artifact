DECLARE @customer_id INT = 42;
DECLARE @phone_pattern NVARCHAR(255) = '+1-555-0000042';

DECLARE @results TABLE (
    object_name NVARCHAR(255),
    rows_found INT
);

-- Check dbo.customer for any column that might contain the phone number
-- Since the phone column was dropped, we check all remaining columns for the phone pattern
INSERT INTO @results (object_name, rows_found)
SELECT 
    'dbo.customer',
    SUM(CASE 
            WHEN full_name LIKE '%' + @phone_pattern + '%' 
              OR email LIKE '%' + @phone_pattern + '%' 
            THEN 1 
            ELSE 0 
        END)
FROM dbo.customer
WHERE customer_id = @customer_id;

-- Check all other tables and columns in the database for the phone number
-- Using dynamic SQL to search all character-based columns in all user tables
DECLARE @table_schema NVARCHAR(128);
DECLARE @table_name NVARCHAR(128);
DECLARE @column_name NVARCHAR(128);
DECLARE @sql NVARCHAR(MAX);
DECLARE @full_table_name NVARCHAR(255);

DECLARE table_cursor CURSOR FOR
SELECT 
    s.name AS schema_name,
    t.name AS table_name,
    c.name AS column_name
FROM sys.columns c
JOIN sys.tables t ON c.object_id = t.object_id
JOIN sys.schemas s ON t.schema_id = s.schema_id
JOIN sys.types ty ON c.user_type_id = ty.user_type_id
WHERE ty.name IN ('nvarchar', 'varchar', 'nchar', 'char', 'ntext', 'text', 'sysname')
  AND NOT (s.name = 'dbo' AND t.name = 'customer')  -- already checked above
ORDER BY s.name, t.name, c.name;

OPEN table_cursor;
FETCH NEXT FROM table_cursor INTO @table_schema, @table_name, @column_name;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @full_table_name = QUOTENAME(@table_schema) + '.' + QUOTENAME(@table_name);
    SET @sql = N'SELECT @cnt = COUNT(*) FROM ' + @full_table_name + 
               N' WHERE ' + QUOTENAME(@column_name) + N' LIKE ''%' + @phone_pattern + N'%''';
    
    DECLARE @cnt INT = 0;
    EXEC sp_executesql @sql, N'@cnt INT OUTPUT', @cnt OUTPUT;
    
    IF @cnt > 0
    BEGIN
        INSERT INTO @results (object_name, rows_found)
        VALUES (@full_table_name, @cnt);
    END
    ELSE
    BEGIN
        -- Still include the object with 0 rows found
        INSERT INTO @results (object_name, rows_found)
        VALUES (@full_table_name, 0);
    END
    
    FETCH NEXT FROM table_cursor INTO @table_schema, @table_name, @column_name;
END

CLOSE table_cursor;
DEALLOCATE table_cursor;

-- If no other objects were found, ensure at least dbo.customer is present
IF NOT EXISTS (SELECT 1 FROM @results WHERE object_name = 'dbo.customer')
BEGIN
    INSERT INTO @results (object_name, rows_found)
    VALUES ('dbo.customer', 0);
END

-- Return final result set
SELECT object_name, rows_found
FROM @results
ORDER BY object_name;
