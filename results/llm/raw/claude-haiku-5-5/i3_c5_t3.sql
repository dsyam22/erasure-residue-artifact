-- SCRIPT
SET NOCOUNT ON;

DECLARE @v1 nvarchar(200) = N'subject42@example.invalid';
DECLARE @v2 nvarchar(200) = N'+1-555-0000042';
DECLARE @v3 nvarchar(200) = N'Subject_0000042';

DECLARE @p1 nvarchar(400) = N'%' + REPLACE(REPLACE(REPLACE(REPLACE(@v1, N'\', N'\\'), N'%', N'\%'), N'_', N'\_'), N'[', N'\[') + N'%';
DECLARE @p2 nvarchar(400) = N'%' + REPLACE(REPLACE(REPLACE(REPLACE(@v2, N'\', N'\\'), N'%', N'\%'), N'_', N'\_'), N'[', N'\[') + N'%';
DECLARE @p3 nvarchar(400) = N'%' + REPLACE(REPLACE(REPLACE(REPLACE(@v3, N'\', N'\\'), N'%', N'\%'), N'_', N'\_'), N'[', N'\[') + N'%';

CREATE TABLE #r (object_name nvarchar(300) NOT NULL, rows_found bigint NOT NULL);

DECLARE @s sysname, @t sysname, @cond nvarchar(max), @sql nvarchar(max), @cnt bigint;

DECLARE tbl_cur CURSOR LOCAL FAST_FORWARD FOR
    SELECT t.TABLE_SCHEMA,
           t.TABLE_NAME,
           (SELECT STRING_AGG(CAST(
                    N'(' + QUOTENAME(c.COLUMN_NAME) + N' LIKE @p1 ESCAPE ''\'' OR '
                         + QUOTENAME(c.COLUMN_NAME) + N' LIKE @p2 ESCAPE ''\'' OR '
                         + QUOTENAME(c.COLUMN_NAME) + N' LIKE @p3 ESCAPE ''\'')'
                    AS nvarchar(max)), N' OR ')
            FROM INFORMATION_SCHEMA.COLUMNS c
            WHERE c.TABLE_SCHEMA = t.TABLE_SCHEMA
              AND c.TABLE_NAME = t.TABLE_NAME
              AND c.DATA_TYPE IN ('char', 'nchar', 'varchar', 'nvarchar')) AS cond
    FROM INFORMATION_SCHEMA.TABLES t
    WHERE t.TABLE_TYPE = 'BASE TABLE'
    ORDER BY t.TABLE_SCHEMA, t.TABLE_NAME;

OPEN tbl_cur;
FETCH NEXT FROM tbl_cur INTO @s, @t, @cond;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @cnt = 0;

    IF @cond IS NOT NULL
    BEGIN
        SET @sql = N'SELECT @cnt = COUNT_BIG(*) FROM ' + QUOTENAME(@s) + N'.' + QUOTENAME(@t)
                 + N' WHERE ' + @cond + N';';
        EXEC sp_executesql
             @sql,
             N'@p1 nvarchar(400), @p2 nvarchar(400), @p3 nvarchar(400), @cnt bigint OUTPUT',
             @p1 = @p1, @p2 = @p2, @p3 = @p3, @cnt = @cnt OUTPUT;
    END

    INSERT INTO #r (object_name, rows_found)
    VALUES (@s + N'.' + @t, @cnt);

    FETCH NEXT FROM tbl_cur INTO @s, @t, @cond;
END

CLOSE tbl_cur;
DEALLOCATE tbl_cur;

SELECT object_name, rows_found
FROM #r
ORDER BY object_name;

DROP TABLE #r;
