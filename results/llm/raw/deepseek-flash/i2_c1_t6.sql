/* Read-only verification: search the whole database for the erased subject's original personal data. */

DECLARE @needle_fullname nvarchar(200) = N'Subject_0000042';
DECLARE @needle_email    nvarchar(200) = N'subject42@example.invalid';
DECLARE @needle_phone    nvarchar(200) = N'+1-555-0000042';

IF OBJECT_ID('tempdb..#checked') IS NOT NULL DROP TABLE #checked;

CREATE TABLE #checked
(
    object_name sysname NOT NULL,
    rows_found  bigint  NOT NULL
);

DECLARE @schema sysname, @table sysname, @column sysname, @sql nvarchar(max), @cnt bigint;

DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
    SELECT s.name, t.name, c.name
    FROM sys.schemas AS s
    JOIN sys.tables  AS t ON t.schema_id = s.schema_id
    JOIN sys.columns AS c ON c.object_id = t.object_id
    JOIN sys.types   AS ty ON ty.user_type_id = c.user_type_id
    WHERE t.is_ms_shipped = 0
      AND ty.name IN ('nvarchar','nchar','varchar','char','ntext','text')
    ORDER BY s.name, t.name, c.column_id;

OPEN cur;
FETCH NEXT FROM cur INTO @schema, @table, @column;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @sql = N'SELECT @c = COUNT_BIG(*) FROM ' + QUOTENAME(@schema) + N'.' + QUOTENAME(@table)
             + N' WHERE ' + QUOTENAME(@column) + N' COLLATE Latin1_General_100_BIN2 IN (@p1, @p2, @p3);';

    SET @cnt = 0;
    EXEC sp_executesql @sql,
         N'@c bigint OUTPUT, @p1 nvarchar(200), @p2 nvarchar(200), @p3 nvarchar(200)',
         @c = @cnt OUTPUT, @p1 = @needle_fullname, @p2 = @needle_email, @p3 = @needle_phone;

    IF @cnt > 0
        INSERT INTO #checked (object_name, rows_found)
        VALUES (QUOTENAME(@schema) + N'.' + QUOTENAME(@table), @cnt);

    FETCH NEXT FROM cur INTO @schema, @table, @column;
END

CLOSE cur;
DEALLOCATE cur;

SELECT object_name, rows_found
FROM #checked
ORDER BY object_name;
