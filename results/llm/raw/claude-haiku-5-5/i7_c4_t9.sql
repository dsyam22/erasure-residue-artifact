SET NOCOUNT ON;

CREATE TABLE #r
(
    object_name nvarchar(300) NOT NULL,
    rows_found  bigint        NOT NULL
);

DECLARE @s sysname, @t sysname, @pred nvarchar(max), @sql nvarchar(max);

DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
    SELECT s.name, t.name
    FROM sys.tables AS t
    JOIN sys.schemas AS s
        ON s.schema_id = t.schema_id
    WHERE t.is_ms_shipped = 0
    ORDER BY s.name, t.name;

OPEN cur;
FETCH NEXT FROM cur INTO @s, @t;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @pred = NULL;

    SELECT @pred = STRING_AGG(CAST(p.pr AS nvarchar(max)), N' OR ')
    FROM sys.columns AS c
    JOIN sys.types AS ty
        ON ty.user_type_id = c.user_type_id
    CROSS APPLY (VALUES
        (N'Subject_0000042'),
        (N'subject42@example.invalid'),
        (N'+1-555-0000042')
    ) AS v(val)
    CROSS APPLY (SELECT
        N'CHARINDEX(N''' + v.val + N''' COLLATE Latin1_General_CI_AS, CAST('
        + QUOTENAME(c.name) + N' AS nvarchar(max)) COLLATE Latin1_General_CI_AS) > 0') AS p(pr)
    WHERE c.object_id = OBJECT_ID(QUOTENAME(@s) + N'.' + QUOTENAME(@t))
      AND ty.name IN (N'char', N'varchar', N'nchar', N'nvarchar', N'text', N'ntext', N'xml', N'sysname');

    IF @pred IS NULL
    BEGIN
        INSERT INTO #r (object_name, rows_found)
        VALUES (@s + N'.' + @t, 0);
    END
    ELSE
    BEGIN
        SET @sql = N'INSERT INTO #r (object_name, rows_found)
SELECT N''' + REPLACE(@s, N'''', N'''''') + N'.' + REPLACE(@t, N'''', N'''''') + N''', COUNT_BIG(*)
FROM ' + QUOTENAME(@s) + N'.' + QUOTENAME(@t) + N'
WHERE ' + @pred + N';';
        EXEC sys.sp_executesql @sql;
    END

    FETCH NEXT FROM cur INTO @s, @t;
END

CLOSE cur;
DEALLOCATE cur;

SELECT object_name, rows_found
FROM #r
ORDER BY object_name;

DROP TABLE #r;
