-- SCRIPT
SET NOCOUNT ON;

DECLARE @customer_id int = 42;
DECLARE @full_name nvarchar(200) = N'Subject_0000042';
DECLARE @email nvarchar(200) = N'subject42@example.invalid';
DECLARE @phone nvarchar(200) = N'+1-555-0000042';

DECLARE @results TABLE (object_name sysname, rows_found int);

-- Check dbo.customer
INSERT INTO @results (object_name, rows_found)
SELECT N'dbo.customer', COUNT(*)
FROM dbo.customer
WHERE customer_id = @customer_id
   OR full_name = @full_name
   OR email = @email
   OR phone = @phone;

-- Check every other user base table / column for the subject's personal data
DECLARE @schema sysname, @table sysname, @column sysname, @sql nvarchar(max);
DECLARE @cnt int;
DECLARE @cid nvarchar(200) = CAST(@customer_id AS nvarchar(200));

DECLARE col_cursor CURSOR LOCAL FAST_FORWARD FOR
SELECT c.TABLE_SCHEMA, c.TABLE_NAME, c.COLUMN_NAME
FROM INFORMATION_SCHEMA.COLUMNS c
JOIN INFORMATION_SCHEMA.TABLES t
  ON t.TABLE_SCHEMA = c.TABLE_SCHEMA
 AND t.TABLE_NAME = c.TABLE_NAME
WHERE t.TABLE_TYPE = 'BASE TABLE'
  AND c.DATA_TYPE IN ('char','varchar','nchar','nvarchar','text','ntext','int','bigint','smallint','tinyint')
  AND NOT (c.TABLE_SCHEMA = 'dbo' AND c.TABLE_NAME = 'customer');

OPEN col_cursor;
FETCH NEXT FROM col_cursor INTO @schema, @table, @column;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @cnt = 0;

    SET @sql = N'SELECT @cnt = COUNT(*) FROM ' + QUOTENAME(@schema) + N'.' + QUOTENAME(@table)
             + N' WHERE CAST(' + QUOTENAME(@column) + N' AS nvarchar(max)) IN (@v1, @v2, @v3, @v4)';

    EXEC sp_executesql @sql,
         N'@cnt int OUTPUT, @v1 nvarchar(200), @v2 nvarchar(200), @v3 nvarchar(200), @v4 nvarchar(200)',
         @cnt OUTPUT, @full_name, @email, @phone, @full_name;

    IF @cnt = 0
    BEGIN
        SET @sql = N'SELECT @cnt = COUNT(*) FROM ' + QUOTENAME(@schema) + N'.' + QUOTENAME(@table)
                 + N' WHERE CAST(' + QUOTENAME(@column) + N' AS nvarchar(max)) = @v1';
        EXEC sp_executesql @sql,
             N'@cnt int OUTPUT, @v1 nvarchar(200)',
             @cnt OUTPUT, @cid;
    END

    IF @cnt > 0
    BEGIN
        INSERT INTO @results (object_name, rows_found)
        VALUES (QUOTENAME(@schema) + N'.' + QUOTENAME(@table) + N'.' + QUOTENAME(@column), @cnt);
    END

    FETCH NEXT FROM col_cursor INTO @schema, @table, @column;
END

CLOSE col_cursor;
DEALLOCATE col_cursor;

SELECT object_name, rows_found FROM @results;
