SET NOCOUNT ON;

DECLARE @v1 nvarchar(200) = N'Subject_0000042';
DECLARE @v2 nvarchar(200) = N'subject42@example.invalid';
DECLARE @v3 nvarchar(200) = N'+1-555-0000042';

CREATE TABLE #results
(
    object_name nvarchar(300) NOT NULL,
    rows_found  bigint        NOT NULL
);

DECLARE @oid int, @s sysname, @t sysname, @obj nvarchar(300);
DECLARE @pred nvarchar(max), @sql nvarchar(max);

DECLARE tbl_cur CURSOR LOCAL FAST_FORWARD FOR
    SELECT t.object_id, s.name, t.name
    FROM sys.tables AS t
    JOIN sys.schemas AS s ON s.schema_id = t.schema_id
    WHERE t.is_ms_shipped = 0
    ORDER BY s.name, t.name;

OPEN tbl_cur;
FETCH NEXT FROM tbl_cur INTO @oid, @s, @t;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @obj = @s + N'.' + @t;
    SET @pred = NULL;

    -- Build a predicate that tests every character-type column of the table
    SELECT @pred = STRING_AGG(
            CONVERT(nvarchar(max),
                N'(CHARINDEX(@v1, CAST(' + QUOTENAME(c.name) + N' AS nvarchar(max))) > 0 OR '
              + N'CHARINDEX(@v2, CAST(' + QUOTENAME(c.name) + N' AS nvarchar(max))) > 0 OR '
              + N'CHARINDEX(@v3, CAST(' + QUOTENAME(c.name) + N' AS nvarchar(max))) > 0)'),
            N' OR ')
    FROM sys.columns AS c
    WHERE c.object_id = @oid
      AND c.system_type_id IN (167, 175, 231, 239, 35, 99); -- varchar, char, nvarchar, nchar, text, ntext

    IF @pred IS NULL
    BEGIN
        INSERT INTO #results (object_name, rows_found) VALUES (@obj, 0);
    END
    ELSE
    BEGIN
        SET @sql = N'INSERT INTO #results (object_name, rows_found) '
                 + N'SELECT @obj, COUNT(*) FROM '
                 + QUOTENAME(@s) + N'.' + QUOTENAME(@t)
                 + N' WHERE ' + @pred + N';';

        EXEC sp_executesql
            @sql,
            N'@obj nvarchar(300), @v1 nvarchar(200), @v2 nvarchar(200), @v3 nvarchar(200)',
            @obj = @obj, @v1 = @v1, @v2 = @v2, @v3 = @v3;
    END

    FETCH NEXT FROM tbl_cur INTO @oid, @s, @t;
END

CLOSE tbl_cur;
DEALLOCATE tbl_cur;

SELECT object_name, rows_found
FROM #results
ORDER BY object_name;

DROP TABLE #results;
