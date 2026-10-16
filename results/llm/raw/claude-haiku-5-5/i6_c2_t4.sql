SET NOCOUNT ON;

DECLARE @phone nvarchar(50) = N'+1-555-0000042';

CREATE TABLE #results (
    object_name sysname NOT NULL,
    rows_found  bigint  NOT NULL
);

DECLARE @schema sysname, @table sysname, @objid int;
DECLARE @pred nvarchar(max), @sql nvarchar(max), @n bigint;

DECLARE tbl_cur CURSOR LOCAL FAST_FORWARD FOR
    SELECT s.name, t.name, t.object_id
    FROM sys.tables AS t
    JOIN sys.schemas AS s ON s.schema_id = t.schema_id
    WHERE t.is_ms_shipped = 0
    ORDER BY s.name, t.name;

OPEN tbl_cur;
FETCH NEXT FROM tbl_cur INTO @schema, @table, @objid;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @pred = NULL;
    SET @n = 0;

    -- Build a predicate over all character columns of the current table
    SELECT @pred = STRING_AGG(
               CAST(QUOTENAME(c.name) + N' LIKE N''%' + REPLACE(@phone, N'''', N'''''') + N'%''' AS nvarchar(max)),
               N' OR ')
    FROM sys.columns AS c
    JOIN sys.types AS ty ON ty.user_type_id = c.user_type_id
    WHERE c.object_id = @objid
      AND ty.name IN (N'char', N'varchar', N'nchar', N'nvarchar', N'sysname');

    IF @pred IS NULL
    BEGIN
        SET @n = 0;
    END
    ELSE
    BEGIN
        SET @sql = N'SELECT @n_out = COUNT_BIG(*) FROM '
                 + QUOTENAME(@schema) + N'.' + QUOTENAME(@table)
                 + N' WHERE ' + @pred + N';';
        EXEC sp_executesql @sql, N'@n_out bigint OUTPUT', @n_out = @n OUTPUT;
    END

    INSERT INTO #results (object_name, rows_found)
    VALUES (CONVERT(sysname, @schema + N'.' + @table), @n);

    FETCH NEXT FROM tbl_cur INTO @schema, @table, @objid;
END

CLOSE tbl_cur;
DEALLOCATE tbl_cur;

SELECT object_name, rows_found
FROM #results
ORDER BY object_name;
