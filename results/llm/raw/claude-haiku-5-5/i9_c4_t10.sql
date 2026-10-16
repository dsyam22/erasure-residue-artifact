SET NOCOUNT ON;

DECLARE @p1 nvarchar(100) = N'Subject_0000042';
DECLARE @p2 nvarchar(100) = N'subject42@example.invalid';
DECLARE @p3 nvarchar(100) = N'+1-555-0000042';

CREATE TABLE #results (
    object_name nvarchar(400) NOT NULL,
    rows_found  bigint        NOT NULL
);

DECLARE @schema sysname, @table sysname, @objid int;
DECLARE @cond nvarchar(max), @sql nvarchar(max), @n bigint;

DECLARE tcur CURSOR LOCAL FAST_FORWARD FOR
    SELECT s.name, t.name, t.object_id
    FROM sys.tables t
    JOIN sys.schemas s ON s.schema_id = t.schema_id
    WHERE t.is_ms_shipped = 0
    ORDER BY s.name, t.name;

OPEN tcur;
FETCH NEXT FROM tcur INTO @schema, @table, @objid;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @cond = NULL;
    SET @n = 0;

    -- Build one OR-ed predicate over all text-like columns of this table
    SELECT @cond = STRING_AGG(CAST(
             '(CHARINDEX(@p1, CAST(' + QUOTENAME(c.name) + ' AS nvarchar(max))) > 0 OR '
           + 'CHARINDEX(@p2, CAST(' + QUOTENAME(c.name) + ' AS nvarchar(max))) > 0 OR '
           + 'CHARINDEX(@p3, CAST(' + QUOTENAME(c.name) + ' AS nvarchar(max))) > 0)' AS nvarchar(max)), N' OR ')
    FROM sys.columns c
    WHERE c.object_id = @objid
      AND TYPE_NAME(c.user_type_id) IN ('char','varchar','nchar','nvarchar','text','ntext','xml');

    IF @cond IS NOT NULL
    BEGIN
        SET @sql = N'SELECT @n_out = COUNT(*) FROM ' + QUOTENAME(@schema) + N'.' + QUOTENAME(@table)
                 + N' WHERE ' + @cond + N';';
        EXEC sp_executesql
             @sql,
             N'@p1 nvarchar(100), @p2 nvarchar(100), @p3 nvarchar(100), @n_out bigint OUTPUT',
             @p1 = @p1, @p2 = @p2, @p3 = @p3, @n_out = @n OUTPUT;
    END

    INSERT INTO #results (object_name, rows_found)
    VALUES (@schema + N'.' + @table, @n);

    FETCH NEXT FROM tcur INTO @schema, @table, @objid;
END

CLOSE tcur;
DEALLOCATE tcur;

SELECT object_name, rows_found
FROM #results
ORDER BY object_name;

DROP TABLE #results;
