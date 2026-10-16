SET NOCOUNT ON;

DECLARE @schema sysname = N'dbo';
DECLARE @table sysname = N'customer';
DECLARE @sql nvarchar(max);

DECLARE @history_schema sysname;
DECLARE @history_table sysname;

SELECT
    @history_schema = hs.name,
    @history_table = ht.name
FROM sys.tables t
JOIN sys.schemas s ON t.schema_id = s.schema_id
LEFT JOIN sys.tables ht ON t.history_table_id = ht.object_id
LEFT JOIN sys.schemas hs ON ht.schema_id = hs.schema_id
WHERE s.name = @schema
  AND t.name = @table;

SET @sql = N'
SELECT N''' + @schema + N'.' + @table + N''' AS object_name, COUNT(*) AS rows_found
FROM ' + QUOTENAME(@schema) + N'.' + QUOTENAME(@table) + N'
WHERE customer_id = 42
   OR full_name = N''Subject_0000042''
   OR email = N''subject42@example.invalid''
   OR phone = N''+1-555-0000042''';

IF @history_table IS NOT NULL
BEGIN
    SET @sql = @sql + N'
UNION ALL
SELECT N''' + @history_schema + N'.' + @history_table + N''' AS object_name, COUNT(*) AS rows_found
FROM ' + QUOTENAME(@history_schema) + N'.' + QUOTENAME(@history_table) + N'
WHERE customer_id = 42
   OR full_name = N''Subject_0000042''
   OR email = N''subject42@example.invalid''
   OR phone = N''+1-555-0000042''';
END;

SET @sql = @sql + N'
ORDER BY object_name;';

EXEC sp_executesql @sql;
