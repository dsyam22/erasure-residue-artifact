SET NOCOUNT ON;

DECLARE @results TABLE
(
    object_name sysname NOT NULL,
    rows_found bigint NOT NULL
);

DECLARE @schema_name sysname,
        @table_name sysname,
        @object_id int,
        @where nvarchar(max),
        @sql nvarchar(max),
        @cnt bigint;

DECLARE table_cursor CURSOR LOCAL FORWARD_ONLY READ_ONLY FOR
SELECT s.name, t.name, t.object_id
FROM sys.tables AS t
INNER JOIN sys.schemas AS s
    ON t.schema_id = s.schema_id;

OPEN table_cursor;

FETCH NEXT FROM table_cursor INTO @schema_name, @table_name, @object_id;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @where = NULL;

    SELECT @where = COALESCE(@where + N' OR ', N'') +
           N'TRY_CONVERT(nvarchar(max), ' + QUOTENAME(c.name) + N') IN (N''42'', N''Subject_0000042'', N''subject42@example.invalid'', N''+1-555-0000042'')'
    FROM sys.columns AS c
    INNER JOIN sys.types AS ty
        ON c.system_type_id = ty.user_type_id
    WHERE c.object_id = @object_id
      AND ty.name IN (
          N'int', N'bigint', N'smallint', N'tinyint',
          N'decimal', N'numeric', N'money', N'smallmoney',
          N'float', N'real', N'bit',
          N'char', N'varchar', N'text',
          N'nchar', N'nvarchar', N'ntext',
          N'uniqueidentifier',
          N'date', N'datetime', N'datetime2', N'smalldatetime', N'datetimeoffset', N'time',
          N'xml'
      );

    IF @where IS NOT NULL
    BEGIN
        SET @sql = N'SELECT @cnt = COUNT_BIG(*) FROM ' +
                   QUOTENAME(@schema_name) + N'.' + QUOTENAME(@table_name) +
                   N' WHERE ' + @where + N';';

        EXEC sp_executesql @sql, N'@cnt bigint OUTPUT', @cnt OUTPUT;
    END
    ELSE
    BEGIN
        SET @cnt = 0;
    END;

    INSERT INTO @results (object_name, rows_found)
    VALUES (@schema_name + N'.' + @table_name, @cnt);

    FETCH NEXT FROM table_cursor INTO @schema_name, @table_name, @object_id;
END;

CLOSE table_cursor;
DEALLOCATE table_cursor;

SELECT object_name, rows_found
FROM @results
ORDER BY object_name;
