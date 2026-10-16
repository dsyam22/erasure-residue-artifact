SET NOCOUNT ON;

DECLARE @name  nvarchar(200) = N'Subject_0000042';
DECLARE @email nvarchar(200) = N'subject42@example.invalid';
DECLARE @phone nvarchar(50)  = N'+1-555-0000042';

CREATE TABLE #results (
    object_name nvarchar(300) NOT NULL,
    rows_found  bigint        NOT NULL
);

DECLARE @schema sysname, @table sysname, @obj nvarchar(300),
        @where nvarchar(max), @sql nvarchar(max);

DECLARE tbl_cur CURSOR LOCAL FAST_FORWARD FOR
    SELECT s.name, t.name
    FROM sys.tables AS t
    JOIN sys.schemas AS s ON s.schema_id = t.schema_id
    WHERE t.is_ms_shipped = 0
    ORDER BY s.name, t.name;

OPEN tbl_cur;
FETCH NEXT FROM tbl_cur INTO @schema, @table;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @obj = QUOTENAME(@schema) + N'.' + QUOTENAME(@table);
    SET @where = NULL;

    -- Character-type columns only (varchar, nvarchar, char, nchar)
    SELECT @where = STRING_AGG(
               CAST(N'CAST(' + QUOTENAME(c.name) + N' AS nvarchar(max)) IN (@name, @email, @phone)' AS nvarchar(max)),
               N' OR ')
    FROM sys.columns AS c
    WHERE c.object_id = OBJECT_ID(@obj)
      AND c.system_type_id IN (167, 231, 175, 239);

    SET @sql = N'INSERT INTO #results (object_name, rows_found) '
             + N'SELECT @o, COUNT_BIG(*) FROM ' + @obj
             + N' WHERE ' + ISNULL(@where, N'1 = 0') + N';';

    EXEC sys.sp_executesql
         @sql,
         N'@o nvarchar(300), @name nvarchar(200), @email nvarchar(200), @phone nvarchar(50)',
         @o = @obj, @name = @name, @email = @email, @phone = @phone;

    FETCH NEXT FROM tbl_cur INTO @schema, @table;
END

CLOSE tbl_cur;
DEALLOCATE tbl_cur;

SELECT object_name, rows_found
FROM #results
ORDER BY object_name;

DROP TABLE #results;
