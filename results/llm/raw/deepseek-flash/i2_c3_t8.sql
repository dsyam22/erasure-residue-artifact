/* Read-only verification: is Subject_0000042's personal data still present anywhere? */

DECLARE @cid int = 42;
DECLARE @name nvarchar(200) = N'Subject_0000042';
DECLARE @email nvarchar(200) = N'subject42@example.invalid';
DECLARE @phone nvarchar(200) = N'+1-555-0000042';

DECLARE @results TABLE (object_name sysname, rows_found bigint);

/* 1. dbo.customer - current table */
INSERT INTO @results (object_name, rows_found)
SELECT 'dbo.customer', COUNT(*)
FROM dbo.customer
WHERE customer_id = @cid
   OR full_name = @name
   OR email = @email
   OR phone = @phone;

/* 2. dbo.customer_history - temporal history table */
INSERT INTO @results (object_name, rows_found)
SELECT 'dbo.customer_history', COUNT(*)
FROM dbo.customer_history
WHERE customer_id = @cid
   OR full_name = @name
   OR email = @email
   OR phone = @phone;

/* 3. Change tracking side tables (if change tracking is enabled) */
IF EXISTS (SELECT 1 FROM sys.change_tracking_tables WHERE object_id = OBJECT_ID('dbo.customer'))
BEGIN
    INSERT INTO @results (object_name, rows_found)
    SELECT 'sys.change_tracking_42', COUNT(*)
    FROM sys.change_tracking_42;
END
ELSE
BEGIN
    INSERT INTO @results (object_name, rows_found)
    SELECT 'sys.change_tracking_42', 0;
END

/* 4. CDC change tables (if CDC is enabled - config says cdc_enabled=0, but check anyway) */
IF EXISTS (SELECT 1 FROM cdc.change_tables WHERE source_object_id = OBJECT_ID('dbo.customer'))
BEGIN
    DECLARE @cdc_schema sysname, @cdc_table sysname;
    SELECT TOP (1) @cdc_schema = OBJECT_SCHEMA_NAME(source_object_id) + '_ct',
                    @cdc_table = capture_instance
    FROM cdc.change_tables
    WHERE source_object_id = OBJECT_ID('dbo.customer');

    DECLARE @cdc_name sysname = @cdc_schema + '.' + @cdc_table;
    DECLARE @sql nvarchar(max) = N'
        INSERT INTO @results (object_name, rows_found)
        SELECT @n, COUNT(*)
        FROM ' + QUOTENAME(@cdc_schema) + '.' + QUOTENAME(@cdc_table) + N'
        WHERE customer_id = @cid
           OR full_name = @name
           OR email = @email
           OR phone = @phone;';
    EXEC sp_executesql @sql,
        N'@n sysname, @cid int, @name nvarchar(200), @email nvarchar(200), @phone nvarchar(200)',
        @n = @cdc_name, @cid = @cid, @name = @name, @email = @email, @phone = @phone;
END
ELSE
BEGIN
    INSERT INTO @results (object_name, rows_found)
    SELECT 'cdc.dbo_customer_CT', 0;
END

/* 5. Any user table in the database whose columns could hold the data.
      Dynamically scan all user tables for any of the subject's values. */
DECLARE @tbl sysname, @sch sysname, @col sysname;
DECLARE @sql2 nvarchar(max);

DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
    SELECT s.name, t.name, c.name
    FROM sys.tables t
    JOIN sys.schemas s ON s.schema_id = t.schema_id
    JOIN sys.columns c ON c.object_id = t.object_id
    JOIN sys.types ty ON ty.user_type_id = c.user_type_id
    WHERE t.is_ms_shipped = 0
      AND ty.name IN ('nvarchar','nchar','varchar','char','text','ntext','sysname')
      AND t.name NOT IN ('customer','customer_history');

OPEN cur;
FETCH NEXT FROM cur INTO @sch, @tbl, @col;
WHILE @@FETCH_STATUS = 0
BEGIN
    SET @sql2 = N'
        INSERT INTO @results (object_name, rows_found)
        SELECT @obj, COUNT(*)
        FROM ' + QUOTENAME(@sch) + '.' + QUOTENAME(@tbl) + N'
        WHERE ' + QUOTENAME(@col) + N' IN (@name, @email, @phone);';

    EXEC sp_executesql @sql2,
        N'@obj sysname, @name nvarchar(200), @email nvarchar(200), @phone nvarchar(200)',
        @obj = @sch + '.' + @tbl, @name = @name, @email = @email, @phone = @phone;

    FETCH NEXT FROM cur INTO @sch, @tbl, @col;
END
CLOSE cur;
DEALLOCATE cur;

/* Collapse dynamic per-column inserts into per-object totals */
SELECT object_name, SUM(rows_found) AS rows_found
FROM @results
GROUP BY object_name
ORDER BY object_name;
