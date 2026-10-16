SET NOCOUNT ON;

DECLARE @p_name  nvarchar(200) = N'Subject_0000042';
DECLARE @p_email nvarchar(200) = N'subject42@example.invalid';
DECLARE @p_phone nvarchar(200) = N'+1-555-0000042';
DECLARE @p_cid   int           = 42;

CREATE TABLE #results
(
    object_name nvarchar(300) NOT NULL,
    rows_found  bigint        NOT NULL
);

DECLARE @obj_id   int,
        @objname  nvarchar(300),
        @quoted   nvarchar(400),
        @where    nvarchar(max),
        @sql      nvarchar(max);

DECLARE tbl_cur CURSOR LOCAL FAST_FORWARD FOR
    SELECT t.object_id,
           QUOTENAME(SCHEMA_NAME(t.schema_id)) + N'.' + QUOTENAME(t.name),
           SCHEMA_NAME(t.schema_id) + N'.' + t.name
    FROM sys.tables AS t
    WHERE t.is_ms_shipped = 0
    ORDER BY SCHEMA_NAME(t.schema_id), t.name;

OPEN tbl_cur;
FETCH NEXT FROM tbl_cur INTO @obj_id, @quoted, @objname;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @where = NULL;

    SELECT @where = STRING_AGG(CAST(x.cond AS nvarchar(max)), N' OR ')
    FROM (
        SELECT QUOTENAME(c.name) + N' IN (@p_name, @p_email, @p_phone)' AS cond
        FROM sys.columns AS c
        JOIN sys.types AS ty ON ty.user_type_id = c.user_type_id
        WHERE c.object_id = @obj_id
          AND ty.name IN (N'nvarchar', N'varchar', N'nchar', N'char')
        UNION ALL
        SELECT QUOTENAME(c.name) + N' = @p_cid'
        FROM sys.columns AS c
        WHERE c.object_id = @obj_id
          AND c.name = N'customer_id'
          AND c.system_type_id = 56   -- int
    ) AS x;

    IF @where IS NULL
    BEGIN
        INSERT INTO #results (object_name, rows_found) VALUES (@objname, 0);
    END
    ELSE
    BEGIN
        SET @sql = N'INSERT INTO #results (object_name, rows_found) '
                 + N'SELECT @o, COUNT_BIG(*) FROM ' + @quoted
                 + N' WHERE ' + @where + N';';

        EXEC sp_executesql
             @sql,
             N'@o nvarchar(300), @p_name nvarchar(200), @p_email nvarchar(200), @p_phone nvarchar(200), @p_cid int',
             @o = @objname,
             @p_name = @p_name,
             @p_email = @p_email,
             @p_phone = @p_phone,
             @p_cid = @p_cid;
    END

    FETCH NEXT FROM tbl_cur INTO @obj_id, @quoted, @objname;
END

CLOSE tbl_cur;
DEALLOCATE tbl_cur;

SELECT object_name, rows_found
FROM #results
ORDER BY object_name;

DROP TABLE #results;
