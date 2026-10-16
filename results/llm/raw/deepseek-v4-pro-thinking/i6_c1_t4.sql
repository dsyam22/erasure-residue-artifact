SET NOCOUNT ON;

DECLARE @phone nvarchar(100) = N'+1-555-0000042';
DECLARE @schema sysname;
DECLARE @table sysname;
DECLARE @object_name nvarchar(500);
DECLARE @query_name nvarchar(776);
DECLARE @where nvarchar(max);
DECLARE @sql nvarchar(max);

IF OBJECT_ID('tempdb..#results') IS NOT NULL
    DROP TABLE #results;

CREATE TABLE #results (
    object_name nvarchar(500) NOT NULL,
    rows_found int NOT NULL
);

DECLARE cur CURSOR LOCAL FAST_FORWARD READ_ONLY FOR
SELECT s.name, t.name
FROM sys.tables AS t
JOIN sys.schemas AS s ON t.schema_id = s.schema_id
WHERE t.is_ms_shipped = 0
ORDER BY s.name, t.name;

OPEN cur;
FETCH NEXT FROM cur INTO @schema, @table;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @object_name = @schema + N'.' + @table;
    SET @query_name = QUOTENAME(@schema) + N'.' + QUOTENAME(@table);

    SELECT @where = STRING_AGG(
        CASE
            WHEN ty.name IN (N'char', N'varchar', N'nchar', N'nvarchar')
                THEN N'TRIM(' + QUOTENAME(c.name) + N') = @phone'
            WHEN ty.name IN (N'text', N'ntext')
                THEN N'TRIM(CAST(' + QUOTENAME(c.name) + N' AS nvarchar(max))) = @phone'
            ELSE NULL
        END,
        N' OR '
    )
    FROM sys.columns AS c
    JOIN sys.tables AS t ON c.object_id = t.object_id
    JOIN sys.schemas AS s ON t.schema_id = s.schema_id
    JOIN sys.types AS ty
        ON c.system_type_id = ty.user_type_id
        AND ty.user_type_id = ty.system_type_id
    WHERE s.name = @schema
      AND t.name = @table
      AND ty.name IN (N'char', N'varchar', N'nchar', N'nvarchar', N'text', N'ntext');

    IF @where IS NULL
    BEGIN
        INSERT INTO #results (object_name, rows_found)
        VALUES (@object_name, 0);
    END
    ELSE
    BEGIN
        SET @sql = N'SELECT @obj, COUNT(*) FROM ' + @query_name + N' WHERE ' + @where + N';';

        INSERT INTO #results (object_name, rows_found)
        EXEC sp_executesql
            @sql,
            N'@obj nvarchar(500), @phone nvarchar(100)',
            @obj = @object_name,
            @phone = @phone;
    END

    FETCH NEXT FROM cur INTO @schema, @table;
END

CLOSE cur;
DEALLOCATE cur;

SELECT object_name, rows_found
FROM #results
ORDER BY object_name;

DROP TABLE #results;
