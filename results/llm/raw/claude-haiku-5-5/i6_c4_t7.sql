SET NOCOUNT ON;

DECLARE @phone nvarchar(50) = N'+1-555-0000042';

CREATE TABLE #res (
    object_name nvarchar(300) NOT NULL,
    rows_found  bigint        NOT NULL
);

DECLARE @schema sysname, @table sysname, @cond nvarchar(max), @sql nvarchar(max), @cnt bigint;

DECLARE tbl CURSOR LOCAL FAST_FORWARD FOR
    SELECT s.name, t.name
    FROM sys.tables t
    JOIN sys.schemas s ON s.schema_id = t.schema_id
    ORDER BY s.name, t.name;

OPEN tbl;
FETCH NEXT FROM tbl INTO @schema, @table;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @cond = NULL;
    SET @cnt = 0;

    SELECT @cond = STRING_AGG(
               CAST(N'CHARINDEX(@p, CAST(' + QUOTENAME(c.name)
                    + N' AS nvarchar(max))) > 0' AS nvarchar(max)),
               N' OR ')
    FROM sys.columns c
    JOIN sys.types ty ON ty.user_type_id = c.user_type_id
    WHERE c.object_id = OBJECT_ID(QUOTENAME(@schema) + N'.' + QUOTENAME(@table))
      AND ty.name IN ('char', 'varchar', 'nchar', 'nvarchar', 'text', 'ntext', 'xml');

    SET @sql = N'SELECT @cnt = COUNT(*) FROM ' + QUOTENAME(@schema) + N'.' + QUOTENAME(@table)
             + N' WHERE ' + ISNULL(@cond, N'1 = 0') + N';';

    EXEC sp_executesql
         @sql,
         N'@p nvarchar(50), @cnt bigint OUTPUT',
         @p = @phone,
         @cnt = @cnt OUTPUT;

    INSERT INTO #res (object_name, rows_found)
    VALUES (@schema + N'.' + @table, ISNULL(@cnt, 0));

    FETCH NEXT FROM tbl INTO @schema, @table;
END

CLOSE tbl;
DEALLOCATE tbl;

SELECT object_name, rows_found
FROM #res
ORDER BY object_name;

DROP TABLE #res;
