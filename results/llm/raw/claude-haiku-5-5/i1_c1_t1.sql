SET NOCOUNT ON;

DECLARE @fullName nvarchar(200) = N'Subject_0000042';
DECLARE @email    nvarchar(200) = N'subject42@example.invalid';
DECLARE @phone    nvarchar(200) = N'+1-555-0000042';
DECLARE @cid      int           = 42;

CREATE TABLE #results
(
    object_name nvarchar(400) NOT NULL,
    rows_found  bigint        NOT NULL
);

DECLARE @schema sysname, @name sysname, @oid int;
DECLARE @pred nvarchar(max), @sql nvarchar(max), @n bigint;

DECLARE obj_cur CURSOR LOCAL FAST_FORWARD FOR
    SELECT s.name, o.name, o.object_id
    FROM sys.objects AS o
    JOIN sys.schemas AS s ON s.schema_id = o.schema_id
    WHERE o.type IN ('U', 'V')
      AND o.is_ms_shipped = 0
    ORDER BY s.name, o.name;

OPEN obj_cur;
FETCH NEXT FROM obj_cur INTO @schema, @name, @oid;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @pred = NULL;
    SET @n = 0;

    SELECT @pred = STRING_AGG(CAST(
        CASE
            WHEN t.name = 'int' AND c.name = 'customer_id'
                THEN N'(' + QUOTENAME(c.name) + N' = @cid)'
            WHEN t.name IN ('nvarchar', 'varchar', 'nchar', 'char', 'ntext', 'text')
                THEN N'(CHARINDEX(@fn, CAST(' + QUOTENAME(c.name) + N' AS nvarchar(max)) COLLATE DATABASE_DEFAULT) > 0'
                   + N' OR CHARINDEX(@em, CAST(' + QUOTENAME(c.name) + N' AS nvarchar(max)) COLLATE DATABASE_DEFAULT) > 0'
                   + N' OR CHARINDEX(@ph, CAST(' + QUOTENAME(c.name) + N' AS nvarchar(max)) COLLATE DATABASE_DEFAULT) > 0)'
        END AS nvarchar(max)), N' OR ')
    FROM sys.columns AS c
    JOIN sys.types AS t ON t.user_type_id = c.user_type_id
    WHERE c.object_id = @oid;

    IF @pred IS NOT NULL
    BEGIN
        SET @sql = N'SELECT @n_out = COUNT_BIG(*) FROM '
                 + QUOTENAME(@schema) + N'.' + QUOTENAME(@name)
                 + N' WHERE ' + @pred + N';';

        EXEC sys.sp_executesql
            @sql,
            N'@n_out bigint OUTPUT, @fn nvarchar(200), @em nvarchar(200), @ph nvarchar(200), @cid int',
            @n_out = @n OUTPUT,
            @fn = @fullName,
            @em = @email,
            @ph = @phone,
            @cid = @cid;
    END

    INSERT INTO #results (object_name, rows_found)
    VALUES (@schema + N'.' + @name, ISNULL(@n, 0));

    FETCH NEXT FROM obj_cur INTO @schema, @name, @oid;
END

CLOSE obj_cur;
DEALLOCATE obj_cur;

SELECT object_name, rows_found
FROM #results
ORDER BY object_name;

DROP TABLE #results;
