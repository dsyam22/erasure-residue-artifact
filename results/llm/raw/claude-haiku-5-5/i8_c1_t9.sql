SET NOCOUNT ON;

DECLARE @pName  nvarchar(200) = N'%Subject!_0000042%';
DECLARE @pEmail nvarchar(200) = N'%subject42@example.invalid%';
DECLARE @pPhone nvarchar(200) = N'%+1-555-0000042%';

CREATE TABLE #hits
(
    object_name nvarchar(300) NOT NULL,
    rows_found  int           NOT NULL
);

DECLARE @s sysname, @t sysname, @oid int,
        @where nvarchar(max), @sql nvarchar(max), @cnt int;

DECLARE tbl CURSOR LOCAL FAST_FORWARD FOR
    SELECT s.name, t.name, t.object_id
    FROM sys.tables AS t
    JOIN sys.schemas AS s ON s.schema_id = t.schema_id
    WHERE t.is_ms_shipped = 0
    ORDER BY s.name, t.name;

OPEN tbl;
FETCH NEXT FROM tbl INTO @s, @t, @oid;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @where = NULL;

    SELECT @where = STRING_AGG(CAST(
        N'(CAST(' + QUOTENAME(c.name) + N' AS nvarchar(max)) LIKE @pName ESCAPE ''!'''
      + N' OR CAST(' + QUOTENAME(c.name) + N' AS nvarchar(max)) LIKE @pEmail ESCAPE ''!'''
      + N' OR CAST(' + QUOTENAME(c.name) + N' AS nvarchar(max)) LIKE @pPhone ESCAPE ''!'')'
      AS nvarchar(max)), N' OR ')
    FROM sys.columns AS c
    WHERE c.object_id = @oid
      AND TYPE_NAME(c.system_type_id) IN (N'char', N'varchar', N'nchar', N'nvarchar', N'text', N'ntext', N'xml');

    SET @cnt = 0;

    IF @where IS NOT NULL
    BEGIN
        SET @sql = N'SELECT @c = COUNT(*) FROM '
                 + QUOTENAME(@s) + N'.' + QUOTENAME(@t)
                 + N' WHERE ' + @where + N';';

        EXEC sp_executesql
            @sql,
            N'@c int OUTPUT, @pName nvarchar(200), @pEmail nvarchar(200), @pPhone nvarchar(200)',
            @c = @cnt OUTPUT,
            @pName = @pName,
            @pEmail = @pEmail,
            @pPhone = @pPhone;
    END

    INSERT INTO #hits (object_name, rows_found)
    VALUES (@s + N'.' + @t, @cnt);

    FETCH NEXT FROM tbl INTO @s, @t, @oid;
END

CLOSE tbl;
DEALLOCATE tbl;

SELECT object_name, rows_found
FROM #hits
ORDER BY object_name;
