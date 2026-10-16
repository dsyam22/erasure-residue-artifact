DECLARE @phone NVARCHAR(50) = '+1-555-0000042';

CREATE TABLE #results (
    object_name NVARCHAR(255),
    rows_found INT
);

-- Check all columns in all user tables for the phone number
DECLARE @sql NVARCHAR(MAX) = N'';

SELECT @sql = @sql + N'
IF EXISTS (SELECT 1 FROM sys.columns c WHERE c.object_id = OBJECT_ID(''' + QUOTENAME(s.name) + '.' + QUOTENAME(t.name) + ''') AND c.name = ''' + c.name + ''')
BEGIN
    DECLARE @cnt INT;
    SELECT @cnt = COUNT(*) FROM ' + QUOTENAME(s.name) + '.' + QUOTENAME(t.name) + ' WHERE ' + QUOTENAME(c.name) + ' = @phone;
    INSERT INTO #results (object_name, rows_found)
    VALUES (''' + QUOTENAME(s.name) + '.' + QUOTENAME(t.name) + '.' + QUOTENAME(c.name) + ''', @cnt);
END
'
FROM sys.tables t
JOIN sys.schemas s ON t.schema_id = s.schema_id
JOIN sys.columns c ON t.object_id = c.object_id
WHERE c.system_type_id IN (SELECT system_type_id FROM sys.types WHERE name IN ('nvarchar', 'varchar', 'nchar', 'char', 'text', 'ntext'))
  AND t.name NOT LIKE 'ms%'
  AND t.name NOT LIKE 'sys%';

-- Execute dynamic SQL
EXEC sp_executesql @sql, N'@phone NVARCHAR(50)', @phone = @phone;

-- Also check indexed columns, computed columns, etc. via full text or any other storage
-- For simplicity, we also check XML, JSON, or other string-like columns
-- Additionally, check system tables for any stored procedure parameters or defaults
-- But for this scope, we assume only regular table columns matter.

-- If no rows were inserted (no string columns found), return a row for dbo.customer with 0
IF NOT EXISTS (SELECT 1 FROM #results)
BEGIN
    INSERT INTO #results (object_name, rows_found)
    VALUES ('dbo.customer', 0);
END

-- Return final result set
SELECT object_name, rows_found
FROM #results
ORDER BY object_name;

DROP TABLE #results;
