SET NOCOUNT ON;

DECLARE @customer_id int = 42;
DECLARE @full_name nvarchar(255) = N'Subject_0000042';
DECLARE @email nvarchar(255) = N'subject42@example.invalid';
DECLARE @phone nvarchar(50) = N'+1-555-0000042';

DECLARE @results TABLE (
    object_name nvarchar(300),
    rows_found int
);

-- Check dbo.customer
INSERT INTO @results (object_name, rows_found)
SELECT 
    N'dbo.customer',
    COUNT(*)
FROM dbo.customer
WHERE customer_id = @customer_id
   OR full_name = @full_name
   OR email = @email
   OR phone = @phone;

-- Check all other user tables for columns that might contain personal data
-- This dynamically checks every table for the specific values
DECLARE @sql nvarchar(max);
DECLARE @table_name nvarchar(300);
DECLARE @schema_name nvarchar(128);
DECLARE @column_name nvarchar(128);
DECLARE @full_table_name nvarchar(300);

DECLARE table_cursor CURSOR FOR
SELECT 
    s.name AS schema_name,
    t.name AS table_name,
    c.name AS column_name
FROM sys.tables t
INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
INNER JOIN sys.columns c ON t.object_id = c.object_id
INNER JOIN sys.types ty ON c.user_type_id = ty.user_type_id
WHERE ty.name IN ('nvarchar', 'varchar', 'nchar', 'char', 'ntext', 'text')
  AND NOT (s.name = 'dbo' AND t.name = 'customer')  -- already checked
ORDER BY s.name, t.name, c.name;

OPEN table_cursor;
FETCH NEXT FROM table_cursor INTO @schema_name, @table_name, @column_name;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @full_table_name = QUOTENAME(@schema_name) + '.' + QUOTENAME(@table_name);
    
    SET @sql = N'
        IF EXISTS (SELECT 1 FROM sys.columns 
                   WHERE object_id = OBJECT_ID(@full_table_name) 
                   AND name = @column_name)
        BEGIN
            DECLARE @count int;
            DECLARE @query nvarchar(max);
            SET @query = N''SELECT @cnt = COUNT(*) FROM '' + @full_table_name + 
                         N'' WHERE '' + QUOTENAME(@column_name) + N'' IN (@full_name, @email, @phone)'';
            EXEC sp_executesql @query, 
                N''@cnt int OUTPUT, @full_name nvarchar(255), @email nvarchar(255), @phone nvarchar(50)'',
                @cnt = @count OUTPUT, 
                @full_name = @full_name, 
                @email = @email, 
                @phone = @phone;
            
            IF @count > 0
            BEGIN
                INSERT INTO @results (object_name, rows_found)
                VALUES (@full_table_name + N''.'' + QUOTENAME(@column_name), @count);
            END
        END';
    
    EXEC sp_executesql @sql,
        N'@full_table_name nvarchar(300), @column_name nvarchar(128), @full_name nvarchar(255), @email nvarchar(255), @phone nvarchar(50)',
        @full_table_name = @full_table_name,
        @column_name = @column_name,
        @full_name = @full_name,
        @email = @email,
        @phone = @phone;
    
    FETCH NEXT FROM table_cursor INTO @schema_name, @table_name, @column_name;
END

CLOSE table_cursor;
DEALLOCATE table_cursor;

-- Return results: one row per object checked
SELECT object_name, ISNULL(SUM(rows_found), 0) AS rows_found
FROM (
    -- Include dbo.customer
    SELECT object_name, rows_found FROM @results
    UNION ALL
    -- Include all table.column combinations that were checked (even with 0)
    SELECT 
        QUOTENAME(s.name) + '.' + QUOTENAME(t.name) + '.' + QUOTENAME(c.name) AS object_name,
        0 AS rows_found
    FROM sys.tables t
    INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
    INNER JOIN sys.columns c ON t.object_id = c.object_id
    INNER JOIN sys.types ty ON c.user_type_id = ty.user_type_id
    WHERE ty.name IN ('nvarchar', 'varchar', 'nchar', 'char', 'ntext', 'text')
      AND NOT (s.name = 'dbo' AND t.name = 'customer')
) AS all_checks
GROUP BY object_name
ORDER BY object_name;
