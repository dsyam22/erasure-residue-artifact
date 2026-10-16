SET NOCOUNT ON;

DECLARE @phone NVARCHAR(50) = '+1-555-0000042';
DECLARE @phone_digits NVARCHAR(50) = '15550000042';

DECLARE @results TABLE (
    object_name NVARCHAR(500),
    rows_found BIGINT
);

DECLARE @schema sysname;
DECLARE @table sysname;
DECLARE @quoted_name NVARCHAR(500);
DECLARE @object_id INT;
DECLARE @sql NVARCHAR(MAX);
DECLARE @cnt BIGINT;
DECLARE @cond NVARCHAR(MAX);

DECLARE tables_cursor CURSOR FOR
SELECT s.name,
       t.name,
       QUOTENAME(s.name) + N'.' + QUOTENAME(t.name)
FROM sys.tables t
JOIN sys.schemas s ON t.schema_id = s.schema_id
WHERE s.name IN ('dbo', 'cdc')
  AND t.name LIKE '%customer%'
ORDER BY s.name, t.name;

OPEN tables_cursor;

FETCH NEXT FROM tables_cursor INTO @schema, @table, @quoted_name;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @object_id = OBJECT_ID(@quoted_name);
    SET @cond = N'';
    SET @cnt = 0;

    SELECT @cond = @cond +
           CASE WHEN @cond = N'' THEN N'' ELSE N' OR ' END +
           N'(' +
           N'CHARINDEX(@phone, CONVERT(nvarchar(max), ' + QUOTENAME(c.name) + N')) > 0 OR CHARINDEX(@phone_digits, CONVERT(nvarchar(max), ' + QUOTENAME(c.name) + N')) > 0' +
           N')'
    FROM sys.columns c
    WHERE c.object_id = @object_id
      AND c.system_type_id IN (167, 175, 231, 239)  -- char, varchar, nchar, nvarchar
      AND c.is_computed = 0;

    IF @cond <> N''
    BEGIN
        SET @sql = N'SELECT @cnt = COUNT(*) FROM ' + @quoted_name +
                   N' WHERE ' + @cond + N';';
        EXEC sys.sp_executesql @sql,
             N'@cnt BIGINT OUTPUT, @phone NVARCHAR(50), @phone_digits NVARCHAR(50)',
             @cnt OUTPUT, @phone, @phone_digits;
    END

    INSERT INTO @results (object_name, rows_found)
    VALUES (@schema + N'.' + @table, @cnt);

    FETCH NEXT FROM tables_cursor INTO @schema, @table, @quoted_name;
END

CLOSE tables_cursor;
DEALLOCATE tables_cursor;

SELECT object_name, rows_found
FROM @results
ORDER BY object_name;
