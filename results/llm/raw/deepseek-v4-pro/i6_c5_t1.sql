-- SCRIPT
DECLARE @results TABLE (object_name nvarchar(255), rows_found int);

-- Check dbo.customer for the subject's phone number
INSERT INTO @results (object_name, rows_found)
SELECT 'dbo.customer', COUNT(*)
FROM dbo.customer
WHERE customer_id = 42
  AND (
    full_name LIKE '%+1-555-0000042%'
    OR email LIKE '%+1-555-0000042%'
  );

-- Check all other tables/columns for the phone number
DECLARE @sql nvarchar(max) = N'';
SELECT @sql = @sql + 
    N'INSERT INTO @results (object_name, rows_found) ' +
    N'SELECT ''' + QUOTENAME(s.name) + N'.' + QUOTENAME(t.name) + N''', COUNT(*) ' +
    N'FROM ' + QUOTENAME(s.name) + N'.' + QUOTENAME(t.name) + N' ' +
    N'WHERE ' + QUOTENAME(c.name) + N' LIKE ''%+1-555-0000042%''; '
FROM sys.columns c
JOIN sys.tables t ON c.object_id = t.object_id
JOIN sys.schemas s ON t.schema_id = s.schema_id
WHERE c.system_type_id IN (167, 175, 231, 239)  -- varchar, char, nvarchar, nchar
  AND NOT (s.name = 'dbo' AND t.name = 'customer' AND c.name IN ('full_name', 'email'));

EXEC sp_executesql @sql, N'@results TABLE (object_name nvarchar(255), rows_found int)', @results;

SELECT object_name, rows_found
FROM @results
ORDER BY object_name;
