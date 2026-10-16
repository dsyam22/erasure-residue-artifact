SET NOCOUNT ON;

DECLARE @p_cust_int int = 42;
DECLARE @p_cust_str nvarchar(20) = N'42';
DECLARE @p_name nvarchar(100) = N'Subject_0000042';
DECLARE @p_email nvarchar(100) = N'subject42@example.invalid';
DECLARE @p_phone nvarchar(50) = N'+1-555-0000042';

CREATE TABLE #results (
    object_name nvarchar(258) NOT NULL,
    rows_found bigint NOT NULL
);

DECLARE @schema_name sysname;
DECLARE @table_name sysname;
DECLARE @table_obj_id int;
DECLARE @plain_name nvarchar(258);
DECLARE @cond nvarchar(max);
DECLARE @sql nvarchar(max);
DECLARE @cnt bigint;
DECLARE @params nvarchar(max);

DECLARE tables_cur CURSOR LOCAL FAST_FORWARD FOR
SELECT s.name, t.name, t.object_id
FROM sys.tables AS t
JOIN sys.schemas AS s
    ON t.schema_id = s.schema_id
WHERE t.is_ms_shipped = 0
ORDER BY s.name, t.name;

OPEN tables_cur;
FETCH NEXT FROM tables_cur INTO @schema_name, @table_name, @table_obj_id;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @plain_name = @schema_name + N'.' + @table_name;
    SET @cond = NULL;

    SELECT @cond = STRING_AGG(
        CASE
            WHEN c.name = N'customer_id'
                 AND ty.name IN (N'tinyint', N'smallint', N'int', N'bigint',
                                 N'decimal', N'numeric', N'money', N'smallmoney')
                THEN QUOTENAME(c.name) + N' = @p_cust_int'
            WHEN c.name = N'customer_id'
                 AND ty.name IN (N'char', N'varchar', N'nchar', N'nvarchar')
                THEN QUOTENAME(c.name) + N' = @p_cust_str'
            WHEN c.name = N'full_name'
                 AND ty.name IN (N'char', N'varchar', N'nchar', N'nvarchar')
                THEN QUOTENAME(c.name) + N' = @p_name'
            WHEN c.name = N'email'
                 AND ty.name IN (N'char', N'varchar', N'nchar', N'nvarchar')
                THEN QUOTENAME(c.name) + N' = @p_email'
            WHEN c.name = N'phone'
                 AND ty.name IN (N'char', N'varchar', N'nchar', N'nvarchar')
                THEN QUOTENAME(c.name) + N' = @p_phone'
            ELSE NULL
        END,
        N' OR '
    )
    FROM sys.columns AS c
    JOIN sys.types AS ty
        ON c.system_type_id = ty.system_type_id
       AND ty.system_type_id = ty.user_type_id
    WHERE c.object_id = @table_obj_id
      AND c.name IN (N'customer_id', N'full_name', N'email', N'phone');

    SET @sql = N'SELECT @cnt = COUNT(*) FROM ' + QUOTENAME(@schema_name) + N'.' + QUOTENAME(@table_name);

    IF @cond IS NOT NULL
        SET @sql += N' WHERE ' + @cond;
    ELSE
        SET @sql += N' WHERE 1 = 0';

    SET @params = N'@p_cust_int int, @p_cust_str nvarchar(20), @p_name nvarchar(100), @p_email nvarchar(100), @p_phone nvarchar(50), @cnt bigint OUTPUT';

    SET @cnt = 0;
    EXEC sys.sp_executesql @sql,
                           @params,
                           @p_cust_int = @p_cust_int,
                           @p_cust_str = @p_cust_str,
                           @p_name = @p_name,
                           @p_email = @p_email,
                           @p_phone = @p_phone,
                           @cnt = @cnt OUTPUT;

    INSERT INTO #results (object_name, rows_found)
    VALUES (@plain_name, @cnt);

    FETCH NEXT FROM tables_cur INTO @schema_name, @table_name, @table_obj_id;
END;

CLOSE tables_cur;
DEALLOCATE tables_cur;

SELECT object_name, rows_found
FROM #results
ORDER BY object_name;
