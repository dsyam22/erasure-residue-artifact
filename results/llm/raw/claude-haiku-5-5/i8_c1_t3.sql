SET NOCOUNT ON;

DECLARE @v_name  nvarchar(200) = N'Subject_0000042';
DECLARE @v_email nvarchar(200) = N'subject42@example.invalid';
DECLARE @v_phone nvarchar(200) = N'+1-555-0000042';

CREATE TABLE #results (
    object_name nvarchar(400) NOT NULL,
    rows_found  int           NOT NULL
);

DECLARE @schema sysname, @table sysname, @object_id int;
DECLARE @pred nvarchar(max), @sql nvarchar(max), @cnt int;

DECLARE tbl_cur CURSOR LOCAL FAST_FORWARD FOR
    SELECT s.name, t.name, t.object_id
    FROM sys.tables AS t
    JOIN sys.schemas AS s ON s.schema_id = t.schema_id
    WHERE t.is_ms_shipped = 0;

OPEN tbl_cur;
FETCH NEXT FROM tbl_cur INTO @schema, @table, @object_id;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @pred = NULL;
    SET @cnt  = 0;

    -- Build a predicate over every character-type column of this table
    SELECT @pred = STRING_AGG(
            CAST(
                '(CHARINDEX(@p_name, CAST(' + QUOTENAME(c.name) + N' AS nvarchar(max))) > 0 OR ' +
                'CHARINDEX(@p_email, CAST(' + QUOTENAME(c.name) + N' AS nvarchar(max))) > 0 OR ' +
                'CHARINDEX(@p_phone, CAST(' + QUOTENAME(c.name) + N' AS nvarchar(max))) > 0)'
                AS nvarchar(max)), N' OR ')
    FROM sys.columns AS c
    WHERE c.object_id = @object_id
      AND c.system_type_id IN (35, 99, 167, 175, 231, 239);  -- text, ntext, varchar, char, nvarchar, nchar

    IF @pred IS NOT NULL
    BEGIN
        SET @sql = N'SELECT @c = COUNT(*) FROM ' + QUOTENAME(@schema) + N'.' + QUOTENAME(@table)
                 + N' WHERE ' + @pred + N';';

        EXEC sp_executesql
            @sql,
            N'@p_name nvarchar(200), @p_email nvarchar(200), @p_phone nvarchar(200), @c int OUTPUT',
            @p_name  = @v_name,
            @p_email = @v_email,
            @p_phone = @v_phone,
            @c       = @cnt OUTPUT;
    END

    INSERT INTO #results (object_name, rows_found)
    VALUES (CONVERT(nvarchar(400), @schema + N'.' + @table), ISNULL(@cnt, 0));

    FETCH NEXT FROM tbl_cur INTO @schema, @table, @object_id;
END

CLOSE tbl_cur;
DEALLOCATE tbl_cur;

SELECT object_name, rows_found
FROM #results
ORDER BY object_name;

DROP TABLE #results;
