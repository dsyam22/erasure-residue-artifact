DECLARE @needle nvarchar(100) = N'+1-555-0000042';

DECLARE @results TABLE (object_name sysname, rows_found bigint);

-- Search all user tables (excluding CDC change tables and system tables) for the phone value
DECLARE @schema sysname, @table sysname, @sql nvarchar(max);

DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
SELECT s.name, t.name
FROM sys.tables t
JOIN sys.schemas s ON s.schema_id = t.schema_id
WHERE t.is_ms_shipped = 0
  AND t.name NOT LIKE '%_CT'
  AND t.name NOT LIKE 'cdc%'
  AND t.name NOT LIKE 'systranschemas%'
  AND t.name NOT LIKE 'systranschemas%'
ORDER BY s.name, t.name;

OPEN cur;
FETCH NEXT FROM cur INTO @schema, @table;
WHILE @@FETCH_STATUS = 0
BEGIN
    DECLARE @cols nvarchar(max) = N'';
    SELECT @cols = @cols + N' OR CAST([' + c.name + N'] AS nvarchar(max)) = @needle'
    FROM sys.columns c
    JOIN sys.types ty ON ty.user_type_id = c.user_type_id
    WHERE c.object_id = OBJECT_ID(QUOTENAME(@schema) + N'.' + QUOTENAME(@table))
      AND ty.name IN (N'nvarchar', N'nchar', N'varchar', N'char', N'ntext', N'text');

    IF @cols IS NOT NULL AND @cols <> N''
    BEGIN
        SET @sql = N'SELECT @cnt = COUNT(*) FROM ' + QUOTENAME(@schema) + N'.' + QUOTENAME(@table)
                 + N' WHERE 1=0' + @cols;

        DECLARE @cnt bigint = 0;
        EXEC sp_executesql @sql, N'@needle nvarchar(100), @cnt bigint OUTPUT', @needle = @needle, @cnt = @cnt OUTPUT;

        INSERT INTO @results (object_name, rows_found)
        VALUES (QUOTENAME(@schema) + N'.' + QUOTENAME(@table), @cnt);
    END

    FETCH NEXT FROM cur INTO @schema, @table;
END
CLOSE cur;
DEALLOCATE cur;

-- Check the CDC change table explicitly
IF OBJECT_ID(N'cdc.dbo_customer_CT') IS NOT NULL
BEGIN
    DECLARE @cdc_cnt bigint = 0;
    DECLARE @cdc_cols nvarchar(max) = N'';
    SELECT @cdc_cols = @cdc_cols + N' OR CAST([' + c.name + N'] AS nvarchar(max)) = @needle'
    FROM sys.columns c
    JOIN sys.types ty ON ty.user_type_id = c.user_type_id
    WHERE c.object_id = OBJECT_ID(N'cdc.dbo_customer_CT')
      AND ty.name IN (N'nvarchar', N'nchar', N'varchar', N'char', N'ntext', N'text');

    IF @cdc_cols IS NOT NULL AND @cdc_cols <> N''
    BEGIN
        DECLARE @cdc_sql nvarchar(max) = N'SELECT @cnt = COUNT(*) FROM cdc.dbo_customer_CT WHERE 1=0' + @cdc_cols;
        EXEC sp_executesql @cdc_sql, N'@needle nvarchar(100), @cnt bigint OUTPUT', @needle = @needle, @cnt = @cdc_cnt OUTPUT;
    END

    INSERT INTO @results (object_name, rows_found)
    VALUES (N'cdc.dbo_customer_CT', @cdc_cnt);
END

SELECT object_name, rows_found
FROM @results
ORDER BY object_name;
