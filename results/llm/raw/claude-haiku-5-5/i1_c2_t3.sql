SET NOCOUNT ON;

DECLARE @fn nvarchar(200) = N'Subject_0000042';
DECLARE @em nvarchar(200) = N'subject42@example.invalid';
DECLARE @ph nvarchar(200) = N'+1-555-0000042';

CREATE TABLE #results (
    object_name nvarchar(300) NOT NULL,
    rows_found  bigint        NOT NULL
);

DECLARE @obj_name nvarchar(300), @oid int, @pred nvarchar(max), @sql nvarchar(max), @cnt bigint;

DECLARE obj_cur CURSOR LOCAL FAST_FORWARD FOR
    SELECT QUOTENAME(s.name) + N'.' + QUOTENAME(t.name), t.object_id
    FROM sys.tables AS t
    JOIN sys.schemas AS s ON s.schema_id = t.schema_id
    ORDER BY s.name, t.name;

OPEN obj_cur;
FETCH NEXT FROM obj_cur INTO @obj_name, @oid;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @pred = NULL;

    -- Build predicate over all character columns of this table
    SELECT @pred = STRING_AGG(
               CAST(QUOTENAME(c.name) + N' IN (@fn, @em, @ph)' AS nvarchar(max)),
               N' OR ')
    FROM sys.columns AS c
    JOIN sys.types AS ty ON ty.user_type_id = c.user_type_id
    WHERE c.object_id = @oid
      AND ty.name IN (N'nvarchar', N'varchar', N'nchar', N'char');

    IF @pred IS NULL
    BEGIN
        INSERT INTO #results (object_name, rows_found) VALUES (@obj_name, 0);
    END
    ELSE
    BEGIN
        SET @sql = N'SELECT @n = COUNT_BIG(*) FROM ' + @obj_name
                 + N' WHERE ' + @pred + N';';
        SET @cnt = 0;
        EXEC sys.sp_executesql
             @sql,
             N'@fn nvarchar(200), @em nvarchar(200), @ph nvarchar(200), @n bigint OUTPUT',
             @fn = @fn, @em = @em, @ph = @ph, @n = @cnt OUTPUT;

        INSERT INTO #results (object_name, rows_found) VALUES (@obj_name, @cnt);
    END

    FETCH NEXT FROM obj_cur INTO @obj_name, @oid;
END

CLOSE obj_cur;
DEALLOCATE obj_cur;

SELECT object_name, rows_found
FROM #results
ORDER BY object_name;

DROP TABLE #results;
