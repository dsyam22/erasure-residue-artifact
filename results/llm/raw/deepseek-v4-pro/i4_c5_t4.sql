-- SCRIPT
DECLARE @results TABLE (object_name NVARCHAR(255), rows_found INT);

-- Check dbo.customer for original personal data
INSERT INTO @results (object_name, rows_found)
SELECT 'dbo.customer', COUNT(*)
FROM dbo.customer
WHERE customer_id = 42
  AND (
    full_name = 'Subject_0000042'
    OR email = 'subject42@example.invalid'
    OR phone = '+1-555-0000042'
  );

-- Check dbo.member for original personal data
INSERT INTO @results (object_name, rows_found)
SELECT 'dbo.member', COUNT(*)
FROM dbo.member
WHERE member_id = 42
  AND (
    full_name = 'Subject_0000042'
    OR email = 'subject42@example.invalid'
    OR phone = '+1-555-0000042'
  );

-- Check all other tables in the database for the original personal data
-- This uses dynamic SQL to scan all user tables for any column containing the original values
DECLARE @sql NVARCHAR(MAX) = N'';
DECLARE @table_name NVARCHAR(255);
DECLARE @schema_name NVARCHAR(255);

DECLARE table_cursor CURSOR FOR
SELECT s.name AS schema_name, t.name AS table_name
FROM sys.tables t
INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
WHERE t.name NOT IN ('customer', 'member');

OPEN table_cursor;
FETCH NEXT FROM table_cursor INTO @schema_name, @table_name;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @sql = N'INSERT INTO @results (object_name, rows_found) SELECT ''' + @schema_name + N'.' + @table_name + N''', COUNT(*) FROM ' + QUOTENAME(@schema_name) + N'.' + QUOTENAME(@table_name) + N' WHERE 1=0';
    
    DECLARE @column_name NVARCHAR(255);
    DECLARE column_cursor CURSOR FOR
    SELECT c.name
    FROM sys.columns c
    WHERE c.object_id = OBJECT_ID(QUOTENAME(@schema_name) + N'.' + QUOTENAME(@table_name))
      AND c.system_type_id IN (167, 175, 231, 239, 241) -- varchar, char, nvarchar, nchar, xml
      AND c.name NOT IN ('full_name', 'email', 'phone');
    
    OPEN column_cursor;
    FETCH NEXT FROM column_cursor INTO @column_name;
    
    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @sql = @sql + N' OR ' + QUOTENAME(@column_name) + N' IN (''Subject_0000042'', ''subject42@example.invalid'', ''+1-555-0000042'')';
        FETCH NEXT FROM column_cursor INTO @column_name;
    END
    
    CLOSE column_cursor;
    DEALLOCATE column_cursor;
    
    -- Add the OR conditions for the specific columns if they exist
    SET @sql = @sql + N' OR full_name = ''Subject_0000042'' OR email = ''subject42@example.invalid'' OR phone = ''+1-555-0000042''';
    
    EXEC sp_executesql @sql, N'@results TABLE (object_name NVARCHAR(255), rows_found INT)', @results = @results;
    
    FETCH NEXT FROM table_cursor INTO @schema_name, @table_name;
END

CLOSE table_cursor;
DEALLOCATE table_cursor;

-- Return the results
SELECT object_name, rows_found
FROM @results
ORDER BY object_name;
