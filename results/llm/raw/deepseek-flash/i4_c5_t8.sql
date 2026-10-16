-- SCRIPT
SET NOCOUNT ON;

DECLARE @cid int = 42;
DECLARE @mid int = 42;
DECLARE @name nvarchar(200) = N'Subject_0000042';
DECLARE @email nvarchar(320) = N'subject42@example.invalid';
DECLARE @phone nvarchar(50) = N'+1-555-0000042';

DECLARE @results TABLE (object_name sysname, rows_found int);

-- Check dbo.customer
INSERT INTO @results (object_name, rows_found)
SELECT 'dbo.customer', COUNT(*)
FROM dbo.customer
WHERE customer_id = @cid
  AND (
       full_name = @name
    OR email = @email
    OR phone = @phone
  );

-- Check dbo.member
INSERT INTO @results (object_name, rows_found)
SELECT 'dbo.member', COUNT(*)
FROM dbo.member
WHERE member_id = @mid
  AND (
       full_name = @name
    OR email = @email
    OR phone = @phone
  );

-- Check all user tables for any column that still contains the original values
DECLARE @schema sysname, @table sysname, @column sysname, @sql nvarchar(max);
DECLARE @count int;

DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
SELECT c.TABLE_SCHEMA, c.TABLE_NAME, c.COLUMN_NAME
FROM INFORMATION_SCHEMA.COLUMNS c
JOIN INFORMATION_SCHEMA.TABLES t
  ON t.TABLE_SCHEMA = c.TABLE_SCHEMA
 AND t.TABLE_NAME = c.TABLE_NAME
WHERE t.TABLE_TYPE = 'BASE TABLE'
  AND c.TABLE_SCHEMA NOT IN ('sys', 'INFORMATION_SCHEMA')
  AND c.DATA_TYPE IN ('nvarchar', 'varchar', 'nchar', 'char', 'ntext', 'text')
  AND NOT (c.TABLE_SCHEMA = 'dbo' AND c.TABLE_NAME IN ('customer', 'member'))
ORDER BY c.TABLE_SCHEMA, c.TABLE_NAME, c.COLUMN_NAME;

OPEN cur;
FETCH NEXT FROM cur INTO @schema, @table, @column;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @sql = N'SELECT @cnt = COUNT(*) FROM ' + QUOTENAME(@schema) + N'.' + QUOTENAME(@table)
             + N' WHERE ' + QUOTENAME(@column) + N' IN (@n, @e, @p);';

    EXEC sp_executesql @sql,
        N'@cnt int OUTPUT, @n nvarchar(200), @e nvarchar(320), @p nvarchar(50)',
        @cnt = @count OUTPUT, @n = @name, @e = @email, @p = @phone;

    IF @count > 0
    BEGIN
        INSERT INTO @results (object_name, rows_found)
        VALUES (QUOTENAME(@schema) + N'.' + QUOTENAME(@table) + N'.' + QUOTENAME(@column), @count);
    END

    FETCH NEXT FROM cur INTO @schema, @table, @column;
END

CLOSE cur;
DEALLOCATE cur;

SELECT object_name, rows_found
FROM @results
ORDER BY object_name;
