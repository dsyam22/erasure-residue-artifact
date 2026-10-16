SET NOCOUNT ON;

DECLARE @results TABLE
(
    object_name nvarchar(776) NOT NULL,
    rows_found bigint NOT NULL
);

DECLARE @schema_name sysname;
DECLARE @table_name sysname;
DECLARE @object_name nvarchar(776);
DECLARE @full_object_name nvarchar(776);
DECLARE @object_id int;
DECLARE @condition nvarchar(max);
DECLARE @sql nvarchar(max);
DECLARE @cnt bigint;

DECLARE table_cursor CURSOR LOCAL FAST_FORWARD FOR
    SELECT s.name, t.name, t.object_id
    FROM sys.tables t
    INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
    WHERE t.is_ms_shipped = 0
       OR s.name = N'cdc'
    ORDER BY s.name, t.name;

OPEN table_cursor;

FETCH NEXT FROM table_cursor INTO @schema_name, @table_name, @object_id;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @object_name = @schema_name + N'.' + @table_name;
    SET @full_object_name = QUOTENAME(@schema_name) + N'.' + QUOTENAME(@table_name);
    SET @condition = NULL;

    SELECT @condition = STRING_AGG(
        CASE
            WHEN c.name = N'full_name'
                 AND ty.name IN (N'char', N'varchar', N'nchar', N'nvarchar', N'sysname')
                THEN QUOTENAME(c.name) + N' = N''Subject_0000042'''

            WHEN c.name = N'email'
                 AND ty.name IN (N'char', N'varchar', N'nchar', N'nvarchar', N'sysname')
                THEN QUOTENAME(c.name) + N' = N''subject42@example.invalid'''

            WHEN c.name = N'phone'
                 AND ty.name IN (N'char', N'varchar', N'nchar', N'nvarchar', N'sysname')
                THEN QUOTENAME(c.name) + N' = N''+1-555-0000042'''

            WHEN c.name IN (N'customer_id', N'member_id')
                 AND ty.name IN (N'int', N'bigint', N'smallint', N'tinyint', N'decimal', N'numeric', N'float', N'real')
                THEN QUOTENAME(c.name) + N' = 42'

            WHEN c.name IN (N'customer_id', N'member_id')
                 AND ty.name IN (N'char', N'varchar', N'nchar', N'nvarchar', N'sysname')
                THEN QUOTENAME(c.name) + N' = N''42'''

            ELSE NULL
        END,
        N' OR '
    )
    FROM sys.columns c
    INNER JOIN sys.types ty ON c.user_type_id = ty.user_type_id
    WHERE c.object_id = @object_id
      AND c.name IN (N'full_name', N'email', N'phone', N'customer_id', N'member_id');

    IF @condition IS NULL
        SET @condition = N'1=0';
    ELSE
        SET @condition = N'(' + @condition + N')';

    SET @sql = N'SELECT @cnt = COUNT(*) FROM ' + @full_object_name + N' WHERE ' + @condition + N';';
    SET @cnt = 0;

    EXEC sp_executesql @sql,
         N'@cnt bigint OUTPUT',
         @cnt = @cnt OUTPUT;

    INSERT INTO @results (object_name, rows_found)
    VALUES (@object_name, @cnt);

    FETCH NEXT FROM table_cursor INTO @schema_name, @table_name, @object_id;
END

CLOSE table_cursor;
DEALLOCATE table_cursor;

SELECT object_name, rows_found
FROM @results
ORDER BY object_name;
