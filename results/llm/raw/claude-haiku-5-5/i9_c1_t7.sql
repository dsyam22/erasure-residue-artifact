SET NOCOUNT ON;

DECLARE @p1 nvarchar(200) = N'Subject_0000042';
DECLARE @p2 nvarchar(200) = N'subject42@example.invalid';
DECLARE @p3 nvarchar(200) = N'+1-555-0000042';

DECLARE @results TABLE (
    object_name nvarchar(400) NOT NULL PRIMARY KEY,
    rows_found  bigint        NOT NULL
);

DECLARE @schema sysname, @table sysname, @obj nvarchar(400);
DECLARE @where nvarchar(max), @sql nvarchar(max), @cnt bigint;

DECLARE tbl_cur CURSOR LOCAL FAST_FORWARD FOR
    SELECT t.TABLE_SCHEMA, t.TABLE_NAME
    FROM INFORMATION_SCHEMA.TABLES AS t
    WHERE t.TABLE_TYPE = N'BASE TABLE'
    ORDER BY t.TABLE_SCHEMA, t.TABLE_NAME;

OPEN tbl_cur;
FETCH NEXT FROM tbl_cur INTO @schema, @table;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @obj = QUOTENAME(@schema) + N'.' + QUOTENAME(@table);
    SET @where = NULL;
    SET @cnt = 0;

    -- Build a predicate over every character-type column of this table.
    -- Case-insensitive comparison; CHARINDEX avoids LIKE wildcard issues with '_'.
    SELECT @where = STRING_AGG(
        CAST(
            N'(CHARINDEX(@p1, CAST(' + QUOTENAME(c.COLUMN_NAME) + N' AS nvarchar(max)) COLLATE Latin1_General_CI_AS) > 0'
          + N' OR CHARINDEX(@p2, CAST(' + QUOTENAME(c.COLUMN_NAME) + N' AS nvarchar(max)) COLLATE Latin1_General_CI_AS) > 0'
          + N' OR CHARINDEX(@p3, CAST(' + QUOTENAME(c.COLUMN_NAME) + N' AS nvarchar(max)) COLLATE Latin1_General_CI_AS) > 0)'
        AS nvarchar(max)), N' OR ')
    FROM INFORMATION_SCHEMA.COLUMNS AS c
    WHERE c.TABLE_SCHEMA = @schema
      AND c.TABLE_NAME = @table
      AND c.DATA_TYPE IN (N'char', N'varchar', N'nchar', N'nvarchar', N'text', N'ntext');

    IF @where IS NOT NULL
    BEGIN
        SET @sql = N'SELECT @cnt = COUNT(*) FROM ' + @obj + N' WHERE ' + @where + N';';
        EXEC sp_executesql
            @sql,
            N'@p1 nvarchar(200), @p2 nvarchar(200), @p3 nvarchar(200), @cnt bigint OUTPUT',
            @p1 = @p1, @p2 = @p2, @p3 = @p3, @cnt = @cnt OUTPUT;
    END

    INSERT INTO @results (object_name, rows_found)
    VALUES (@obj, ISNULL(@cnt, 0));

    FETCH NEXT FROM tbl_cur INTO @schema, @table;
END

CLOSE tbl_cur;
DEALLOCATE tbl_cur;

SELECT r.object_name, r.rows_found
FROM @results AS r
ORDER BY r.object_name;
