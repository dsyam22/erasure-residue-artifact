-- SCRIPT
SET NOCOUNT ON;

DECLARE @subject_phone nvarchar(100) = N'+1-555-0000042';

DECLARE @results TABLE (object_name sysname, rows_found bigint);

-- 1. dbo.customer: phone column was dropped, so check all remaining columns
--    for the phone value (in case it was stored in another column).
INSERT INTO @results (object_name, rows_found)
SELECT 'dbo.customer',
       COUNT(*)
FROM dbo.customer
WHERE (CAST(customer_id AS nvarchar(100)) = @subject_phone
    OR full_name = @subject_phone
    OR email = @subject_phone);

-- 2. Scan every other table/column in the database for the phone value.
DECLARE @schema sysname, @table sysname, @column sysname, @sql nvarchar(max), @cnt bigint;

DECLARE col_cursor CURSOR LOCAL FAST_FORWARD FOR
SELECT c.TABLE_SCHEMA, c.TABLE_NAME, c.COLUMN_NAME
FROM INFORMATION_SCHEMA.COLUMNS c
JOIN INFORMATION_SCHEMA.TABLES t
  ON t.TABLE_SCHEMA = c.TABLE_SCHEMA AND t.TABLE_NAME = c.TABLE_NAME
WHERE t.TABLE_TYPE = 'BASE TABLE'
  AND NOT (c.TABLE_SCHEMA = 'dbo' AND c.TABLE_NAME = 'customer')
ORDER BY c.TABLE_SCHEMA, c.TABLE_NAME, c.COLUMN_NAME;

OPEN col_cursor;
FETCH NEXT FROM col_cursor INTO @schema, @table, @column;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @sql = N'SELECT @cnt = COUNT(*) FROM ' + QUOTENAME(@schema) + N'.' + QUOTENAME(@table)
             + N' WHERE CONVERT(nvarchar(max), ' + QUOTENAME(@column) + N') LIKE N''%'' + @p + N''%'';';

    SET @cnt = 0;
    EXEC sp_executesql @sql, N'@p nvarchar(100), @cnt bigint OUTPUT', @p = @subject_phone, @cnt = @cnt OUTPUT;

    IF @cnt > 0
        INSERT INTO @results (object_name, rows_found)
        VALUES (QUOTENAME(@schema) + N'.' + QUOTENAME(@table) + N'.' + QUOTENAME(@column), @cnt);

    FETCH NEXT FROM col_cursor INTO @schema, @table, @column;
END

CLOSE col_cursor;
DEALLOCATE col_cursor;

-- 3. Ensure every checked object appears with 0 if nothing was found.
SELECT object_name, rows_found
FROM @results
ORDER BY object_name;
