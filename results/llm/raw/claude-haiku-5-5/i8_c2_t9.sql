SET NOCOUNT ON;

DECLARE @e nvarchar(200) = N'subject42@example.invalid',
        @n nvarchar(200) = N'Subject_0000042',
        @p nvarchar(200) = N'+1-555-0000042';

CREATE TABLE #t (
    object_name nvarchar(300) NOT NULL PRIMARY KEY,
    obj         nvarchar(400) NOT NULL,
    pred        nvarchar(max) NULL
);

CREATE TABLE #r (
    object_name nvarchar(300) NOT NULL PRIMARY KEY,
    rows_found  int NOT NULL
);

-- Every user table, with a predicate over all character columns (NULL if none)
INSERT INTO #t (object_name, obj, pred)
SELECT
    s.name + N'.' + t.name,
    QUOTENAME(s.name) + N'.' + QUOTENAME(t.name),
    STUFF((
        SELECT N' OR CHARINDEX(@e, ' + QUOTENAME(c.name) + N' COLLATE Latin1_General_CI_AS) > 0'
             + N' OR CHARINDEX(@n, ' + QUOTENAME(c.name) + N' COLLATE Latin1_General_CI_AS) > 0'
             + N' OR CHARINDEX(@p, ' + QUOTENAME(c.name) + N' COLLATE Latin1_General_CI_AS) > 0'
        FROM sys.columns AS c
        JOIN sys.types AS ty ON ty.user_type_id = c.user_type_id
        WHERE c.object_id = t.object_id
          AND ty.name IN (N'char', N'varchar', N'nchar', N'nvarchar')
        FOR XML PATH(N''), TYPE
    ).value('.', 'nvarchar(max)'), 1, 4, N'')
FROM sys.tables AS t
JOIN sys.schemas AS s ON s.schema_id = t.schema_id
WHERE t.is_ms_shipped = 0;

DECLARE @obj nvarchar(300), @qobj nvarchar(400), @pred nvarchar(max),
        @cnt int, @sql nvarchar(max);

DECLARE c CURSOR LOCAL FAST_FORWARD FOR
    SELECT object_name, obj, pred FROM #t ORDER BY object_name;

OPEN c;
FETCH NEXT FROM c INTO @obj, @qobj, @pred;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @cnt = 0;

    IF @pred IS NOT NULL
    BEGIN
        SET @sql = N'SELECT @cnt = COUNT(*) FROM ' + @qobj + N' WHERE ' + @pred + N';';
        EXEC sys.sp_executesql
            @sql,
            N'@e nvarchar(200), @n nvarchar(200), @p nvarchar(200), @cnt int OUTPUT',
            @e = @e, @n = @n, @p = @p, @cnt = @cnt OUTPUT;
    END

    INSERT INTO #r (object_name, rows_found) VALUES (@obj, @cnt);

    FETCH NEXT FROM c INTO @obj, @qobj, @pred;
END

CLOSE c;
DEALLOCATE c;

SELECT object_name, rows_found
FROM #r
ORDER BY object_name;
