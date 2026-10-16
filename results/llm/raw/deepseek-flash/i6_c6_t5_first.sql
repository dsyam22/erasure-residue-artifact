-- SCRIPT
SET NOCOUNT ON;

DECLARE @needle nvarchar(100) = N'+1-555-0000042';

DECLARE @results TABLE (object_name sysname, rows_found int);

-- Check dbo.customer: all text columns present (full_name, email)
INSERT INTO @results (object_name, rows_found)
SELECT 'dbo.customer',
       COUNT(*)
FROM dbo.customer
WHERE CONVERT(nvarchar(max), full_name) LIKE N'%' + @needle + N'%'
   OR CONVERT(nvarchar(max), email) LIKE N'%' + @needle + N'%';

-- Check every other user table/column in the database for the phone number
DECLARE @sql nvarchar(max) = N'';

SELECT @sql = STRING_AGG(
    N'INSERT INTO @results (object_name, rows_found) SELECT ' +
    QUOTENAME(s.name) + N'.' + QUOTENAME(t.name) + N'''' + N' AS object_name, COUNT(*) FROM ' +
    QUOTENAME(s.name) + N'.' + QUOTENAME(t.name) +
    N' WHERE ' +
    STRING_AGG(
        N'CONVERT(nvarchar(max), ' + QUOTENAME(c.name) + N') LIKE N''%' + @needle + N'%''',
        N' OR '
    ) + N';',
    N' '
)
FROM sys.tables t
JOIN sys.schemas s ON s.schema_id = t.schema_id
JOIN sys.columns c ON c.object_id = t.object_id
JOIN sys.types ty ON ty.user_type_id = c.user_type_id
WHERE t.is_ms_shipped = 0
  AND ty.name IN ('char','nchar','varchar','nvarchar','text','ntext','sysname','xml')
  AND NOT (s.name = 'dbo' AND t.name = 'customer')
GROUP BY s.name, t.name;

IF @sql IS NOT NULL
    EXEC sp_executesql @sql, N'@needle nvarchar(100), @results TABLE (object_name sysname, rows_found int) OUTPUT', @needle, @results;

SELECT object_name, rows_found
FROM @results
ORDER BY object_name;
