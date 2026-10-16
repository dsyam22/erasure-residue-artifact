-- SCRIPT
SET NOCOUNT ON;

DECLARE @cid int = 42;
DECLARE @mid int = 42;
DECLARE @full_name nvarchar(200) = N'Subject_0000042';
DECLARE @email nvarchar(200) = N'subject42@example.invalid';
DECLARE @phone nvarchar(200) = N'+1-555-0000042';

DECLARE @results TABLE (object_name sysname, rows_found int);

-- Check dbo.customer
INSERT INTO @results (object_name, rows_found)
SELECT 'dbo.customer',
       COUNT(*)
FROM dbo.customer
WHERE customer_id = @cid
  AND (
        full_name = @full_name
     OR email = @email
     OR phone = @phone
  );

-- Check dbo.member
INSERT INTO @results (object_name, rows_found)
SELECT 'dbo.member',
       COUNT(*)
FROM dbo.member
WHERE member_id = @mid
  AND (
        full_name = @full_name
     OR email = @email
     OR phone = @phone
  );

-- Check all other tables/columns in the database for the original values
DECLARE @schema sysname, @table sysname, @column sysname;
DECLARE @sql nvarchar(max);

DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
SELECT s.name, t.name, c.name
FROM sys.tables t
JOIN sys.schemas s ON s.schema_id = t.schema_id
JOIN sys.columns c ON c.object_id = t.object_id
JOIN sys.types ty ON ty.user_type_id = c.user_type_id
WHERE ty.name IN ('nvarchar','varchar','nchar','char','text','ntext')
  AND NOT (s.name = 'dbo' AND t.name IN ('customer','member'))
  AND t.is_ms_shipped = 0;

OPEN cur;
FETCH NEXT FROM cur INTO @schema, @table, @column;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @sql = N'
    INSERT INTO @results (object_name, rows_found)
    SELECT @obj, COUNT(*)
    FROM ' + QUOTENAME(@schema) + N'.' + QUOTENAME(@table) + N'
    WHERE ' + QUOTENAME(@column) + N' IN (@fn, @em, @ph);';

    EXEC sp_executesql @sql,
        N'@obj sysname, @fn nvarchar(200), @em nvarchar(200), @ph nvarchar(200), @results TABLE',
        @obj = @schema + N'.' + @table,
        @fn = @full_name,
        @em = @email,
        @ph = @phone,
        @results = @results;

    FETCH NEXT FROM cur INTO @schema, @table, @column;
END

CLOSE cur;
DEALLOCATE cur;

SELECT object_name, rows_found
FROM @results
ORDER BY object_name;
