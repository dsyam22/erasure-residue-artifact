SET NOCOUNT ON;

CREATE TABLE #hits
(
    object_name sysname NOT NULL,
    rows_found  bigint  NOT NULL
);

DECLARE @oid      int,
        @obj      nvarchar(400),
        @pred     nvarchar(max),
        @sql      nvarchar(max),
        @cnt      bigint;

DECLARE tbl_cur CURSOR LOCAL FAST_FORWARD FOR
    SELECT t.object_id,
           QUOTENAME(s.name) + N'.' + QUOTENAME(t.name)
    FROM sys.tables AS t
    JOIN sys.schemas AS s ON s.schema_id = t.schema_id
    WHERE t.is_ms_shipped = 0
    ORDER BY s.name, t.name;

OPEN tbl_cur;
FETCH NEXT FROM tbl_cur INTO @oid, @obj;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @pred = NULL;

    SELECT @pred = STRING_AGG(CAST(
            N'CHARINDEX(N''Subject_0000042'', ' + QUOTENAME(c.name) + N') > 0 OR '
          + N'CHARINDEX(N''subject42@example.invalid'', ' + QUOTENAME(c.name) + N') > 0 OR '
          + N'CHARINDEX(N''+1-555-0000042'', ' + QUOTENAME(c.name) + N') > 0'
          AS nvarchar(max)), N' OR ')
    FROM sys.columns AS c
    JOIN sys.types AS ty ON ty.user_type_id = c.user_type_id
    WHERE c.object_id = @oid
      AND ty.name IN (N'char', N'varchar', N'nchar', N'nvarchar');

    SET @cnt = 0;

    IF @pred IS NOT NULL
    BEGIN
        SET @sql = N'SELECT @cnt_out = COUNT(*) FROM ' + @obj
                 + N' WHERE (' + @pred + N');';
        EXEC sp_executesql @sql,
             N'@cnt_out bigint OUTPUT',
             @cnt_out = @cnt OUTPUT;
    END

    INSERT INTO #hits (object_name, rows_found)
    VALUES (@obj, @cnt);

    FETCH NEXT FROM tbl_cur INTO @oid, @obj;
END

CLOSE tbl_cur;
DEALLOCATE tbl_cur;

SELECT
    REPLACE(REPLACE(object_name, N'[', N''), N']', N'') AS object_name,
    rows_found
FROM #hits
ORDER BY object_name;

DROP TABLE #hits;
