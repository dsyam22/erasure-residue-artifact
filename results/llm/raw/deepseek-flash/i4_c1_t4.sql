/* Read-only verification of erasure for subject 42. */
SET NOCOUNT ON;

DECLARE @cid int = 42;
DECLARE @mid int = 42;
DECLARE @full_name nvarchar(200) = N'Subject_0000042';
DECLARE @email nvarchar(320) = N'subject42@example.invalid';
DECLARE @phone nvarchar(50) = N'+1-555-0000042';

DECLARE @results TABLE (object_name sysname, rows_found int);

/* dbo.customer */
INSERT INTO @results (object_name, rows_found)
SELECT N'dbo.customer', COUNT(*)
FROM dbo.customer
WHERE customer_id = @cid
  AND (
        full_name = @full_name
     OR email = @email
     OR phone = @phone
  );

/* dbo.member */
INSERT INTO @results (object_name, rows_found)
SELECT N'dbo.member', COUNT(*)
FROM dbo.member
WHERE member_id = @mid
  AND (
        full_name = @full_name
     OR email = @email
     OR phone = @phone
  );

/* Search every other table/column in the database for the original values. */
DECLARE @schema sysname, @table sysname, @col sysname, @sql nvarchar(max);

DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
SELECT s.name, t.name, c.name
FROM sys.columns AS c
JOIN sys.tables AS t ON t.object_id = c.object_id
JOIN sys.schemas AS s ON s.schema_id = t.schema_id
JOIN sys.types AS ty ON ty.user_type_id = c.user_type_id
WHERE t.is_ms_shipped = 0
  AND ty.name IN ('char','nchar','varchar','nvarchar','text','ntext')
  AND NOT (s.name = 'dbo' AND t.name = 'customer' AND c.name IN ('full_name','email','phone'))
  AND NOT (s.name = 'dbo' AND t.name = 'member'   AND c.name IN ('full_name','email','phone'));

OPEN cur;
FETCH NEXT FROM cur INTO @schema, @table, @col;
WHILE @@FETCH_STATUS = 0
BEGIN
    SET @sql = N'
        INSERT INTO @results (object_name, rows_found)
        SELECT @obj, COUNT(*)
        FROM ' + QUOTENAME(@schema) + N'.' + QUOTENAME(@table) + N'
        WHERE ' + QUOTENAME(@col) + N' IN (@fn, @em, @ph);';

    EXEC sp_executesql
        @sql,
        N'@obj sysname, @fn nvarchar(200), @em nvarchar(320), @ph nvarchar(50), @results TABLE (object_name sysname, rows_found int) READONLY',
        @obj = @schema + N'.' + @table,
        @fn = @full_name,
        @em = @email,
        @ph = @phone,
        @results = @results;

    FETCH NEXT FROM cur INTO @schema, @table, @col;
END
CLOSE cur;
DEALLOCATE cur;

SELECT object_name, rows_found
FROM @results
ORDER BY object_name;
