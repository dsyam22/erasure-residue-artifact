SET NOCOUNT ON;

DECLARE @p1 nvarchar(50) = N'+1-555-0000042';   -- formatted phone of subject customer_id 42
DECLARE @p2 nvarchar(50) = N'15550000042';      -- same number, digits only

CREATE TABLE #results
(
    object_name nvarchar(300) NOT NULL,
    rows_found  bigint        NOT NULL
);

DECLARE @schema sysname, @table sysname, @obj nvarchar(300);
DECLARE @pred nvarchar(max), @sql nvarchar(max), @cnt bigint;

DECLARE tbl CURSOR LOCAL FAST_FORWARD FOR
    SELECT s.name, t.name
    FROM sys.tables AS t
    JOIN sys.schemas AS s ON s.schema_id = t.schema_id
    WHERE t.is_ms_shipped = 0
    ORDER BY s.name, t.name;

OPEN tbl;
FETCH NEXT FROM tbl INTO @schema, @table;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @pred = NULL;
    SET @cnt  = 0;

    -- Build a predicate over every character-type column of this table
    -- (varchar=167, char=175, nvarchar=231, nchar=239)
    SELECT @pred = STRING_AGG(CAST(
               'CHARINDEX(@p1, CAST(' + QUOTENAME(c.name) + ' AS nvarchar(max))) > 0 OR '
             + 'CHARINDEX(@p2, CAST(' + QUOTENAME(c.name) + ' AS nvarchar(max))) > 0'
           AS nvarchar(max)), ' OR ')
    FROM sys.columns AS c
    WHERE c.object_id = OBJECT_ID(QUOTENAME(@schema) + N'.' + QUOTENAME(@table))
      AND c.system_type_id IN (167, 175, 231, 239);

    SET @obj = QUOTENAME(@schema) + N'.' + QUOTENAME(@table);
    SET @sql = N'SELECT @cnt = COUNT(*) FROM ' + @obj
             + N' WHERE ' + COALESCE(@pred, N'1 = 0') + N';';

    EXEC sys.sp_executesql
         @sql,
         N'@p1 nvarchar(50), @p2 nvarchar(50), @cnt bigint OUTPUT',
         @p1 = @p1, @p2 = @p2, @cnt = @cnt OUTPUT;

    INSERT INTO #results (object_name, rows_found)
    VALUES (@schema + N'.' + @table, @cnt);

    FETCH NEXT FROM tbl INTO @schema, @table;
END

CLOSE tbl;
DEALLOCATE tbl;

SELECT object_name, rows_found
FROM #results
ORDER BY object_name;

DROP TABLE #results;
