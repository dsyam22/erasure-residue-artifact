-- SCRIPT
SET NOCOUNT ON;

DECLARE @customer_id int = 42;
DECLARE @full_name nvarchar(200) = N'Subject_0000042';
DECLARE @email nvarchar(200) = N'subject42@example.invalid';
DECLARE @phone nvarchar(200) = N'+1-555-0000042';

DECLARE @results TABLE (object_name sysname, rows_found bigint);

-- dbo.customer
INSERT INTO @results (object_name, rows_found)
SELECT N'dbo.customer',
       COUNT_BIG(*)
FROM dbo.customer
WHERE customer_id = @customer_id
   OR full_name = @full_name
   OR email = @email
   OR phone = @phone;

-- Also check any other user tables/columns that might store the same values
DECLARE @schema sysname, @table sysname, @column sysname;
DECLARE @sql nvarchar(max);

DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
SELECT s.name, t.name, c.name
FROM sys.columns c
JOIN sys.tables t ON t.object_id = c.object_id
JOIN sys.schemas s ON s.schema_id = t.schema_id
WHERE t.is_ms_shipped = 0
  AND c.system_type_id IN (167, 231, 175, 239) -- varchar, nvarchar, char, nchar
  AND NOT (s.name = N'dbo' AND t.name = N'customer');

OPEN cur;
FETCH NEXT FROM cur INTO @schema, @table, @column;
WHILE @@FETCH_STATUS = 0
BEGIN
    SET @sql = N'
    INSERT INTO @results (object_name, rows_found)
    SELECT N''' + REPLACE(@schema + N'.' + @table, N'''', N'''''') + N''', COUNT_BIG(*)
    FROM ' + QUOTENAME(@schema) + N'.' + QUOTENAME(@table) + N'
    WHERE ' + QUOTENAME(@column) + N' IN (@full_name, @email, @phone);';

    EXEC sp_executesql @sql,
        N'@full_name nvarchar(200), @email nvarchar(200), @phone nvarchar(200), @results TABLE (object_name sysname, rows_found bigint) READONLY',
        @full_name = @full_name, @email = @email, @phone = @phone, @results = @results;

    FETCH NEXT FROM cur INTO @schema, @table, @column;
END
CLOSE cur;
DEALLOCATE cur;

SELECT object_name, rows_found
FROM @results
ORDER BY object_name;
