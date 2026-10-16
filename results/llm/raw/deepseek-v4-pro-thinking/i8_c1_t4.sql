SET NOCOUNT ON;

DECLARE @final_sql nvarchar(max) = N'';
DECLARE @schema sysname, @table sysname, @object_id int;
DECLARE @where nvarchar(max);
DECLARE @select nvarchar(max);

DECLARE table_cursor CURSOR LOCAL FORWARD_ONLY READ_ONLY FOR
SELECT s.name, t.name, t.object_id
FROM sys.tables t
JOIN sys.schemas s ON t.schema_id = s.schema_id
WHERE t.is_ms_shipped = 0
  AND t.is_external = 0
ORDER BY s.name, t.name;

OPEN table_cursor;
FETCH NEXT FROM table_cursor INTO @schema, @table, @object_id;

WHILE @@FETCH_STATUS = 0
BEGIN
    SELECT @where = STRING_AGG(cond, N' OR ')
    FROM
    (
        SELECT cond = CASE
            WHEN st.name IN (N'char', N'varchar', N'nchar', N'nvarchar')
                THEN N'(' + QUOTENAME(c.name) + N' IN (N''Subject_0000042'', N''subject42@example.invalid'', N''+1-555-0000042'')'
                     + CASE
                         WHEN LOWER(c.name) IN (N'customer_id', N'customerid', N'cust_id', N'c_id', N'customer_no', N'client_id', N'clientid')
                           OR LOWER(c.name) LIKE N'%customer%id%'
                           OR LOWER(c.name) LIKE N'%cust%id%'
                           OR (LOWER(@table) LIKE N'%customer%' AND LOWER(c.name) = N'id')
                           OR (LOWER(@table) LIKE N'%cust%' AND LOWER(c.name) = N'id')
                         THEN N' OR ' + QUOTENAME(c.name) + N' = N''42'''
                         ELSE N''
                       END
                     + N')'
            WHEN st.name IN (N'text', N'ntext')
                THEN N'(CONVERT(nvarchar(max), ' + QUOTENAME(c.name) + N') IN (N''Subject_0000042'', N''subject42@example.invalid'', N''+1-555-0000042'')'
                     + CASE
                         WHEN LOWER(c.name) IN (N'customer_id', N'customerid', N'cust_id', N'c_id', N'customer_no', N'client_id', N'clientid')
                           OR LOWER(c.name) LIKE N'%customer%id%'
                           OR LOWER(c.name) LIKE N'%cust%id%'
                           OR (LOWER(@table) LIKE N'%customer%' AND LOWER(c.name) = N'id')
                           OR (LOWER(@table) LIKE N'%cust%' AND LOWER(c.name) = N'id')
                         THEN N' OR CONVERT(nvarchar(max), ' + QUOTENAME(c.name) + N') = N''42'''
                         ELSE N''
                       END
                     + N')'
            WHEN st.name IN (N'tinyint', N'smallint', N'int', N'bigint', N'decimal', N'numeric', N'money', N'smallmoney', N'float', N'real')
                THEN CASE
                         WHEN LOWER(c.name) IN (N'customer_id', N'customerid', N'cust_id', N'c_id', N'customer_no', N'client_id', N'clientid')
                           OR LOWER(c.name) LIKE N'%customer%id%'
                           OR LOWER(c.name) LIKE N'%cust%id%'
                           OR (LOWER(@table) LIKE N'%customer%' AND LOWER(c.name) = N'id')
                           OR (LOWER(@table) LIKE N'%cust%' AND LOWER(c.name) = N'id')
                         THEN QUOTENAME(c.name) + N' = 42'
                         ELSE NULL
                     END
            WHEN st.name = N'sql_variant'
                THEN N'(CONVERT(nvarchar(max), ' + QUOTENAME(c.name) + N') IN (N''Subject_0000042'', N''subject42@example.invalid'', N''+1-555-0000042'')'
                     + CASE
                         WHEN LOWER(c.name) IN (N'customer_id', N'customerid', N'cust_id', N'c_id', N'customer_no', N'client_id', N'clientid')
                           OR LOWER(c.name) LIKE N'%customer%id%'
                           OR LOWER(c.name) LIKE N'%cust%id%'
                           OR (LOWER(@table) LIKE N'%customer%' AND LOWER(c.name) = N'id')
                           OR (LOWER(@table) LIKE N'%cust%' AND LOWER(c.name) = N'id')
                         THEN N' OR CONVERT(nvarchar(max), ' + QUOTENAME(c.name) + N') = N''42'''
                         ELSE N''
                       END
                     + N')'
            ELSE NULL
        END
        FROM sys.columns c
        JOIN sys.types st ON c.system_type_id = st.user_type_id
        WHERE c.object_id = @object_id
    ) AS conditions
    WHERE cond IS NOT NULL;

    IF @where IS NULL OR @where = N''
        SET @where = N'1=0';

    SET @select = N'SELECT N' + CHAR(39) + REPLACE(@schema + N'.' + @table, CHAR(39), CHAR(39) + CHAR(39)) + CHAR(39) + N' AS object_name, COUNT_BIG(*) AS rows_found FROM ' + QUOTENAME(@schema) + N'.' + QUOTENAME(@table) + N' WHERE ' + @where;

    IF @final_sql = N''
        SET @final_sql = @select;
    ELSE
        SET @final_sql = @final_sql + N' UNION ALL ' + @select;

    FETCH NEXT FROM table_cursor INTO @schema, @table, @object_id;
END

CLOSE table_cursor;
DEALLOCATE table_cursor;

IF @final_sql = N''
    SET @final_sql = N'SELECT CAST(NULL AS sysname) AS object_name, CAST(NULL AS bigint) AS rows_found WHERE 1=0;';
ELSE
    SET @final_sql = @final_sql + N' ORDER BY object_name;';

EXEC sp_executesql @final_sql;
