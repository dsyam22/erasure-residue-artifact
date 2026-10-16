SET NOCOUNT ON;

DECLARE @results TABLE (
    object_name nvarchar(300) NOT NULL PRIMARY KEY,
    rows_found  bigint        NOT NULL
);

DECLARE @objs TABLE (
    id  int IDENTITY(1,1) PRIMARY KEY,
    sch sysname NOT NULL,
    tbl sysname NOT NULL
);

INSERT INTO @objs (sch, tbl)
SELECT s.name, t.name
FROM sys.tables AS t
JOIN sys.schemas AS s ON s.schema_id = t.schema_id
WHERE t.is_ms_shipped = 0
ORDER BY s.name, t.name;

DECLARE @id   int = 1,
        @max  int = (SELECT COUNT(*) FROM @objs),
        @sch  sysname,
        @tbl  sysname,
        @objname nvarchar(300),
        @pred nvarchar(max),
        @sql  nvarchar(max),
        @cnt  bigint,
        @fqn  nvarchar(400),
        @oid  int;

WHILE @id <= @max
BEGIN
    SELECT @sch = sch, @tbl = tbl FROM @objs WHERE id = @id;

    SET @fqn     = QUOTENAME(@sch) + N'.' + QUOTENAME(@tbl);
    SET @objname = @sch + N'.' + @tbl;
    SET @oid     = OBJECT_ID(@fqn);
    SET @pred    = NULL;

    -- Build a predicate: any character-type column (cast to nvarchar(max))
    -- LIKE any of the subject's original personal data values.
    SELECT @pred = STRING_AGG(
            CAST(
                N'(' +
                N'CAST(' + QUOTENAME(c.name) + N' AS nvarchar(max)) LIKE N''%Subject\_0000042%'' ESCAPE ''\'' OR ' +
                N'CAST(' + QUOTENAME(c.name) + N' AS nvarchar(max)) LIKE N''%subject42@example.invalid%'' ESCAPE ''\'' OR ' +
                N'CAST(' + QUOTENAME(c.name) + N' AS nvarchar(max)) LIKE N''%+1-555-0000042%'' ESCAPE ''\''' +
                N')'
                AS nvarchar(max)),
            N' OR ')
    FROM sys.columns AS c
    WHERE c.object_id = @oid
      AND c.system_type_id IN (35, 99, 167, 175, 231, 239, 241); -- text, ntext, varchar, char, nvarchar, nchar, xml

    IF @pred IS NULL
        SET @pred = N'1 = 0';

    SET @sql = N'SELECT @cnt = COUNT_BIG(*) FROM ' + @fqn + N' WHERE ' + @pred + N';';
    SET @cnt = 0;

    EXEC sys.sp_executesql
         @sql,
         N'@cnt bigint OUTPUT',
         @cnt = @cnt OUTPUT;

    INSERT INTO @results (object_name, rows_found)
    VALUES (@objname, ISNULL(@cnt, 0));

    SET @id = @id + 1;
END;

SELECT object_name, rows_found
FROM @results
ORDER BY object_name;
