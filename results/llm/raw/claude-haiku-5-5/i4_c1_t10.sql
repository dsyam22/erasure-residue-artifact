SET NOCOUNT ON;

DECLARE @n nvarchar(200) = N'Subject_0000042',
        @e nvarchar(320) = N'subject42@example.invalid',
        @p nvarchar(50)  = N'+1-555-0000042';

CREATE TABLE #results (
    object_name nvarchar(300) NOT NULL,
    rows_found  bigint        NOT NULL
);

DECLARE @oid int, @obj nvarchar(300), @cond nvarchar(max), @sql nvarchar(max), @cnt bigint;

DECLARE tbl CURSOR LOCAL FAST_FORWARD FOR
    SELECT t.object_id,
           QUOTENAME(s.name) + N'.' + QUOTENAME(t.name)
    FROM sys.tables AS t
    JOIN sys.schemas AS s ON s.schema_id = t.schema_id
    WHERE t.is_ms_shipped = 0;

OPEN tbl;
FETCH NEXT FROM tbl INTO @oid, @obj;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @cond = NULL;
    SET @cnt = 0;

    SELECT @cond = STRING_AGG(
               CAST(QUOTENAME(c.name) + N' IN (@n, @e, @p)' AS nvarchar(max)),
               N' OR ')
    FROM sys.columns AS c
    JOIN sys.types AS ty ON ty.user_type_id = c.user_type_id
    WHERE c.object_id = @oid
      AND ty.name IN (N'char', N'varchar', N'nchar', N'nvarchar');

    IF @cond IS NOT NULL
    BEGIN
        SET @sql = N'SELECT @c = COUNT_BIG(*) FROM ' + @obj + N' WHERE ' + @cond + N';';
        EXEC sys.sp_executesql
             @sql,
             N'@n nvarchar(200), @e nvarchar(320), @p nvarchar(50), @c bigint OUTPUT',
             @n = @n, @e = @e, @p = @p, @c = @cnt OUTPUT;
    END

    INSERT INTO #results (object_name, rows_found)
    VALUES (@obj, @cnt);

    FETCH NEXT FROM tbl INTO @oid, @obj;
END

CLOSE tbl;
DEALLOCATE tbl;

SELECT object_name, rows_found
FROM #results
ORDER BY object_name;

DROP TABLE #results;
