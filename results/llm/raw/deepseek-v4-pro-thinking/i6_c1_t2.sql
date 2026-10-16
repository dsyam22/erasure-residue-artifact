SET NOCOUNT ON;

DECLARE @results TABLE (
    object_name nvarchar(500) NOT NULL,
    rows_found bigint NOT NULL
);

DECLARE @tables TABLE (
    id int IDENTITY(1,1) PRIMARY KEY,
    schema_name sysname NOT NULL,
    table_name sysname NOT NULL,
    object_id int NOT NULL
);

DECLARE @phone nvarchar(50) = N'+1-555-0000042';
DECLARE @i int = 1;
DECLARE @max int;
DECLARE @schema sysname;
DECLARE @table sysname;
DECLARE @object_id int;
DECLARE @object nvarchar(500);
DECLARE @filter nvarchar(max);
DECLARE @sql nvarchar(max);

INSERT INTO @tables (schema_name, table_name, object_id)
SELECT s.name, t.name, t.object_id
FROM sys.tables AS t
JOIN sys.schemas AS s ON t.schema_id = s.schema_id;

SET @max = (SELECT COUNT(*) FROM @tables);

WHILE @i <= @max
BEGIN
    SELECT @schema = schema_name,
           @table = table_name,
           @object_id = object_id,
           @object = schema_name + N'.' + table_name
    FROM @tables
    WHERE id = @i;

    SET @filter = NULL;

    SELECT @filter = STRING_AGG(
        N'CHARINDEX(@phone, CONVERT(nvarchar(max), ' + QUOTENAME(c.name) + N')) > 0',
        N' OR '
    )
    FROM sys.columns AS c
    JOIN sys.types AS ty ON c.system_type_id = ty.user_type_id
    WHERE c.object_id = @object_id
      AND ty.name IN (N'char', N'varchar', N'nchar', N'nvarchar', N'text', N'ntext', N'xml');

    IF @filter IS NOT NULL
    BEGIN
        SET @sql = N'SELECT @object AS object_name, COUNT_BIG(*) AS rows_found FROM '
                 + QUOTENAME(@schema) + N'.' + QUOTENAME(@table)
                 + N' WHERE ' + @filter;

        INSERT INTO @results (object_name, rows_found)
        EXEC sys.sp_executesql @sql,
            N'@phone nvarchar(50), @object nvarchar(500)',
            @phone = @phone,
            @object = @object;
    END
    ELSE
    BEGIN
        INSERT INTO @results (object_name, rows_found)
        VALUES (@object, 0);
    END

    SET @i = @i + 1;
END

SELECT object_name, rows_found
FROM @results
ORDER BY object_name;
