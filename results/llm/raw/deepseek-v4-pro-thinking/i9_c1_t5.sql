SET NOCOUNT ON;

DECLARE @results TABLE (object_name nvarchar(257) NOT NULL, rows_found bigint NOT NULL);
DECLARE @tables TABLE (id int IDENTITY(1,1), schema_name sysname, table_name sysname, object_id int);

INSERT INTO @tables (schema_name, table_name, object_id)
SELECT s.name, t.name, t.object_id
FROM sys.tables AS t
JOIN sys.schemas AS s ON t.schema_id = s.schema_id
WHERE t.type = N'U'
  AND t.is_ms_shipped = 0;

DECLARE @i int = 1;
DECLARE @table_count int = (SELECT COUNT(*) FROM @tables);
DECLARE @schema_name sysname;
DECLARE @table_name sysname;
DECLARE @object_id int;
DECLARE @object_name nvarchar(257);
DECLARE @conditions nvarchar(max);
DECLARE @sql nvarchar(max);
DECLARE @cnt bigint;

WHILE @i <= @table_count
BEGIN
    SELECT @schema_name = schema_name,
           @table_name = table_name,
           @object_id = object_id
    FROM @tables
    WHERE id = @i;

    SET @object_name = @schema_name + N'.' + @table_name;

    SET @conditions = NULL;

    SELECT @conditions = STRING_AGG(
        CASE
            WHEN ty.name IN (N'tinyint', N'smallint', N'int', N'bigint')
                THEN QUOTENAME(c.name) + N' = 42'
            WHEN ty.name IN (N'char', N'varchar', N'nchar', N'nvarchar')
                THEN QUOTENAME(c.name) + N' IN (N''Subject_0000042'', N''subject42@example.invalid'', N''+1-555-0000042'', N''42'')'
            WHEN ty.name IN (N'decimal', N'numeric', N'money', N'smallmoney', N'float', N'real')
                THEN QUOTENAME(c.name) + N' = 42'
            ELSE NULL
        END,
        N' OR '
    )
    FROM sys.columns AS c
    JOIN sys.types AS ty ON ty.user_type_id = c.system_type_id
    WHERE c.object_id = @object_id;

    IF @conditions IS NULL OR @conditions = N''
        SET @cnt = 0;
    ELSE
    BEGIN
        SET @sql = N'SET NOCOUNT ON; SELECT @cnt_out = COUNT_BIG(*) FROM '
                 + QUOTENAME(@schema_name) + N'.' + QUOTENAME(@table_name)
                 + N' WHERE ' + @conditions;

        SET @cnt = 0;
        EXEC sp_executesql @sql, N'@cnt_out bigint OUTPUT', @cnt_out = @cnt OUTPUT;
    END

    INSERT INTO @results (object_name, rows_found)
    VALUES (@object_name, @cnt);

    SET @i = @i + 1;
END

SELECT object_name, rows_found
FROM @results
ORDER BY object_name;
