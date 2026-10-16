SET NOCOUNT ON;

DECLARE @needle nvarchar(50) = N'+1-555-0000042';  -- subject 42 original phone

CREATE TABLE #results (
    object_name nvarchar(400) NOT NULL,
    rows_found  bigint        NOT NULL
);

DECLARE @schema sysname, @table sysname, @objname nvarchar(400),
        @pred nvarchar(max), @sql nvarchar(max), @cnt bigint;

DECLARE tbl_cur CURSOR LOCAL FAST_FORWARD FOR
    SELECT s.name, t.name
    FROM sys.tables AS t
    JOIN sys.schemas AS s ON s.schema_id = t.schema_id;

OPEN tbl_cur;
FETCH NEXT FROM tbl_cur INTO @schema, @table;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @objname = QUOTENAME(@schema) + N'.' + QUOTENAME(@table);

    -- Build a predicate over all character-type columns of this table
    SELECT @pred = STRING_AGG(
               CAST(QUOTENAME(c.name) + N' LIKE N''%' + @needle + N'%''' AS nvarchar(max)),
               N' OR ')
    FROM sys.columns AS c
    WHERE c.object_id = OBJECT_ID(@objname)
      AND c.system_type_id IN (167, 175, 231, 239);  -- varchar, char, nvarchar, nchar

    IF @pred IS NULL
        SET @cnt = 0;
    ELSE
    BEGIN
        SET @sql = N'SELECT @n = COUNT(*) FROM ' + @objname + N' WHERE ' + @pred + N';';
        EXEC sys.sp_executesql @sql, N'@n bigint OUTPUT', @n = @cnt OUTPUT;
    END

    INSERT INTO #results (object_name, rows_found)
    VALUES (@schema + N'.' + @table, ISNULL(@cnt, 0));

    FETCH NEXT FROM tbl_cur INTO @schema, @table;
END

CLOSE tbl_cur;
DEALLOCATE tbl_cur;

SELECT object_name, rows_found
FROM #results
ORDER BY object_name;

DROP TABLE #results;
