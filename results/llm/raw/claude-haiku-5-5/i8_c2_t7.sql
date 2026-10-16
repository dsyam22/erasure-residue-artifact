SET NOCOUNT ON;

DECLARE @v_name  nvarchar(200) = N'Subject_0000042';
DECLARE @v_email nvarchar(200) = N'subject42@example.invalid';
DECLARE @v_phone nvarchar(200) = N'+1-555-0000042';

-- LIKE patterns with wildcard characters escaped (escape char = backslash)
DECLARE @pn nvarchar(400) = N'%' + REPLACE(REPLACE(REPLACE(@v_name,  N'\', N'\\'), N'%', N'\%'), N'_', N'\_') + N'%';
DECLARE @pe nvarchar(400) = N'%' + REPLACE(REPLACE(REPLACE(@v_email, N'\', N'\\'), N'%', N'\%'), N'_', N'\_') + N'%';
DECLARE @pp nvarchar(400) = N'%' + REPLACE(REPLACE(REPLACE(@v_phone, N'\', N'\\'), N'%', N'\%'), N'_', N'\_') + N'%';

CREATE TABLE #results
(
    object_name nvarchar(400) NOT NULL,
    rows_found  bigint        NOT NULL
);

DECLARE @s sysname, @t sysname;
DECLARE @where nvarchar(max), @sql nvarchar(max);
DECLARE @cnt bigint;

DECLARE tbl CURSOR LOCAL FAST_FORWARD FOR
    SELECT TABLE_SCHEMA, TABLE_NAME
    FROM INFORMATION_SCHEMA.TABLES
    WHERE TABLE_TYPE = 'BASE TABLE'
    ORDER BY TABLE_SCHEMA, TABLE_NAME;

OPEN tbl;
FETCH NEXT FROM tbl INTO @s, @t;

WHILE @@FETCH_STATUS = 0
BEGIN
    -- Build a predicate: any character-type column matches any of the three values
    SELECT @where = COALESCE(
        STRING_AGG(
            N'(' + e + N' LIKE @pn ESCAPE ''\'' OR '
                 + e + N' LIKE @pe ESCAPE ''\'' OR '
                 + e + N' LIKE @pp ESCAPE ''\'')',
            N' OR '),
        N'1=0')
    FROM (
        SELECT N'CAST(' + QUOTENAME(c.COLUMN_NAME) + N' AS nvarchar(max))' AS e
        FROM INFORMATION_SCHEMA.COLUMNS AS c
        WHERE c.TABLE_SCHEMA = @s
          AND c.TABLE_NAME   = @t
          AND c.DATA_TYPE IN ('char', 'varchar', 'nchar', 'nvarchar', 'text', 'ntext', 'xml')
    ) AS x;

    SET @sql = N'SELECT @cnt = COUNT(*) FROM '
             + QUOTENAME(@s) + N'.' + QUOTENAME(@t)
             + N' WHERE ' + @where + N';';

    SET @cnt = 0;
    EXEC sys.sp_executesql
         @sql,
         N'@cnt bigint OUTPUT, @pn nvarchar(400), @pe nvarchar(400), @pp nvarchar(400)',
         @cnt OUTPUT, @pn, @pe, @pp;

    INSERT INTO #results (object_name, rows_found)
    VALUES (CONCAT(@s, N'.', @t), @cnt);

    FETCH NEXT FROM tbl INTO @s, @t;
END;

CLOSE tbl;
DEALLOCATE tbl;

SELECT object_name, rows_found
FROM #results
ORDER BY object_name;
