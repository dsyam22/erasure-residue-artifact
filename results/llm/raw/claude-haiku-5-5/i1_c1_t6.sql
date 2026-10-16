SET NOCOUNT ON;

DECLARE @n NVARCHAR(50)  = N'Subject_0000042';
DECLARE @e NVARCHAR(200) = N'subject42@example.invalid';
DECLARE @p NVARCHAR(50)  = N'+1-555-0000042';

CREATE TABLE #residual_check
(
    object_name NVARCHAR(400) NOT NULL,
    rows_found  BIGINT        NOT NULL
);

DECLARE @schema SYSNAME, @table SYSNAME;
DECLARE @where NVARCHAR(MAX), @sql NVARCHAR(MAX), @cnt BIGINT;

DECLARE tbl_cur CURSOR LOCAL FAST_FORWARD FOR
    SELECT s.name, t.name
    FROM sys.tables AS t
    JOIN sys.schemas AS s ON s.schema_id = t.schema_id
    ORDER BY s.name, t.name;

OPEN tbl_cur;
FETCH NEXT FROM tbl_cur INTO @schema, @table;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @where = NULL;
    SET @cnt = 0;

    -- Build a predicate over all character-type columns of this table
    -- (system_type_id: varchar=167, char=175, nvarchar=231, nchar=239)
    SELECT @where = STRING_AGG(CAST(
           N'CHARINDEX(@n COLLATE Latin1_General_CI_AS, ' + QUOTENAME(c.name) + N' COLLATE Latin1_General_CI_AS) > 0'
         + N' OR CHARINDEX(@e COLLATE Latin1_General_CI_AS, ' + QUOTENAME(c.name) + N' COLLATE Latin1_General_CI_AS) > 0'
         + N' OR CHARINDEX(@p COLLATE Latin1_General_CI_AS, ' + QUOTENAME(c.name) + N' COLLATE Latin1_General_CI_AS) > 0'
         AS NVARCHAR(MAX)), N' OR ')
    FROM sys.columns AS c
    WHERE c.object_id = OBJECT_ID(QUOTENAME(@schema) + N'.' + QUOTENAME(@table))
      AND c.system_type_id IN (167, 175, 231, 239);

    SET @sql = N'SELECT @cnt = COUNT(*) FROM ' + QUOTENAME(@schema) + N'.' + QUOTENAME(@table)
             + CASE WHEN @where IS NULL
                    THEN N' WHERE 1 = 0'
                    ELSE N' WHERE ' + @where
               END + N';';

    EXEC sys.sp_executesql
         @sql,
         N'@n NVARCHAR(50), @e NVARCHAR(200), @p NVARCHAR(50), @cnt BIGINT OUTPUT',
         @n = @n, @e = @e, @p = @p, @cnt = @cnt OUTPUT;

    INSERT INTO #residual_check (object_name, rows_found)
    VALUES (@schema + N'.' + @table, @cnt);

    FETCH NEXT FROM tbl_cur INTO @schema, @table;
END;

CLOSE tbl_cur;
DEALLOCATE tbl_cur;

SELECT object_name, rows_found
FROM #residual_check
ORDER BY object_name;

DROP TABLE #residual_check;
