SET NOCOUNT ON;

DECLARE @phone nvarchar(100) = N'+1-555-0000042';
DECLARE @cid int = 42;
DECLARE @email nvarchar(320) = N'subject42@example.invalid';

DECLARE @results TABLE (object_name sysname, rows_found int);

/* dbo.customer: phone column dropped, but check any remaining column for the phone value */
IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.customer') AND name = 'phone')
BEGIN
    INSERT INTO @results (object_name, rows_found)
    SELECT 'dbo.customer', COUNT(*)
    FROM dbo.customer
    WHERE customer_id = @cid
      AND (CAST(phone AS nvarchar(max)) LIKE '%' + @phone + '%');
END
ELSE
BEGIN
    INSERT INTO @results (object_name, rows_found) VALUES ('dbo.customer', 0);
END

/* CDC capture instance table: check the phone column if it still exists */
IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('cdc.dbo_customer_CT') AND name = 'phone')
BEGIN
    INSERT INTO @results (object_name, rows_found)
    SELECT 'cdc.dbo_customer_CT', COUNT(*)
    FROM cdc.dbo_customer_CT
    WHERE customer_id = @cid
      AND (CAST(phone AS nvarchar(max)) LIKE '%' + @phone + '%');
END
ELSE
BEGIN
    INSERT INTO @results (object_name, rows_found) VALUES ('cdc.dbo_customer_CT', 0);
END

/* Scan all other user tables/columns for the phone value (read-only, dynamic) */
DECLARE @sql nvarchar(max) = N'';
DECLARE @schema sysname, @table sysname, @column sysname, @type sysname;

DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
    SELECT s.name, t.name, c.name, ty.name
    FROM sys.columns c
    JOIN sys.tables t ON c.object_id = t.object_id
    JOIN sys.schemas s ON t.schema_id = s.schema_id
    JOIN sys.types ty ON c.user_type_id = ty.user_type_id
    WHERE t.is_ms_shipped = 0
      AND s.name NOT IN ('cdc')
      AND NOT (s.name = 'dbo' AND t.name = 'customer')
      AND ty.name IN ('nvarchar','varchar','nchar','char','ntext','text','xml')
      AND c.is_computed = 0;

OPEN cur;
FETCH NEXT FROM cur INTO @schema, @table, @column, @type;
WHILE @@FETCH_STATUS = 0
BEGIN
    SET @sql = @sql + N'INSERT INTO @results (object_name, rows_found) SELECT ''' 
        + REPLACE(@schema + '.' + @table, '''', '''''') + ''', COUNT(*) FROM '
        + QUOTENAME(@schema) + '.' + QUOTENAME(@table)
        + N' WHERE CAST(' + QUOTENAME(@column) + N' AS nvarchar(max)) LIKE ''%' + REPLACE(@phone, '''', '''''') + N'%'';'
    FETCH NEXT FROM cur INTO @schema, @table, @column, @type;
END
CLOSE cur;
DEALLOCATE cur;

IF @sql <> N''
    EXEC sp_executesql @sql, N'@results TABLE (object_name sysname, rows_found int) OUTPUT', @results = @results OUTPUT;

SELECT object_name, rows_found FROM @results;
