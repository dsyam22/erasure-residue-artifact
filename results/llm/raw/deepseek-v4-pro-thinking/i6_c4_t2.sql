SET NOCOUNT ON;

DECLARE @phone nvarchar(50) = N'+1-555-0000042';

CREATE TABLE #results (
    object_name nvarchar(500) NOT NULL,
    rows_found bigint NOT NULL
);

DECLARE @schema sysname, @table sysname;
DECLARE @obj_name nvarchar(500);
DECLARE @obj_quoted nvarchar(500);
DECLARE @where nvarchar(max);
DECLARE @sql nvarchar(max);

DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
    SELECT TABLE_SCHEMA, TABLE_NAME
    FROM INFORMATION_SCHEMA.TABLES
    WHERE TABLE_TYPE = N'BASE TABLE'
    ORDER BY TABLE_SCHEMA, TABLE_NAME;

OPEN cur;

FETCH NEXT FROM cur INTO @schema, @table;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @obj_name = @schema + N'.' + @table;
    SET @obj_quoted = QUOTENAME(@schema) + N'.' + QUOTENAME(@table);

    SET @where = NULL;

    SELECT @where = STRING_AGG(
        N'CHARINDEX(@phone, CONVERT(nvarchar(max), ' + QUOTENAME(COLUMN_NAME) + N')) > 0',
        N' OR '
    ) WITHIN GROUP (ORDER BY ORDINAL_POSITION)
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = @schema
      AND TABLE_NAME = @table
      AND DATA_TYPE IN (N'char', N'varchar', N'nchar', N'nvarchar', N'text', N'ntext');

    IF @where IS NULL
        SET @where = N'1 = 0';

    SET @sql = N'INSERT INTO #results (object_name, rows_found) ' +
               N'SELECT @obj_name, COUNT(*) FROM ' + @obj_quoted +
               N' WHERE ' + @where + N';';

    EXEC sys.sp_executesql @sql,
         N'@obj_name nvarchar(500), @phone nvarchar(50)',
         @obj_name = @obj_name,
         @phone = @phone;

    FETCH NEXT FROM cur INTO @schema, @table;
END;

CLOSE cur;
DEALLOCATE cur;

SELECT object_name, rows_found
FROM #results
ORDER BY object_name;

DROP TABLE #results;
