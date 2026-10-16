/* Read-only verification: does any residual copy of the subject's personal data remain? */

DECLARE @cid    int           = 42;
DECLARE @name   nvarchar(200) = N'Subject_0000042';
DECLARE @email  nvarchar(200) = N'subject42@example.invalid';
DECLARE @phone  nvarchar(200) = N'+1-555-0000042';

IF OBJECT_ID('tempdb..#res') IS NOT NULL DROP TABLE #res;
CREATE TABLE #res (object_name sysname, rows_found bigint);

/* 1. dbo.customer (current rows) */
INSERT INTO #res (object_name, rows_found)
SELECT 'dbo.customer', COUNT(*)
FROM dbo.customer
WHERE customer_id = @cid
   OR full_name = @name
   OR email = @email
   OR phone = @phone;

/* 2. dbo.customer_history (temporal history) */
IF OBJECT_ID('dbo.customer_history') IS NOT NULL
    INSERT INTO #res (object_name, rows_found)
    SELECT 'dbo.customer_history', COUNT(*)
    FROM dbo.customer_history
    WHERE customer_id = @cid
       OR full_name = @name
       OR email = @email
       OR phone = @phone;
ELSE
    INSERT INTO #res (object_name, rows_found) VALUES ('dbo.customer_history', 0);

/* 3. CDC change tables (cdc.dbo_customer_CT etc.) - only if CDC is enabled */
IF EXISTS (SELECT 1 FROM sys.databases WHERE name = DB_NAME() AND is_cdc_enabled = 1)
BEGIN
    DECLARE @ct sysname, @sql nvarchar(max);

    DECLARE cdc_cur CURSOR LOCAL FAST_FORWARD FOR
        SELECT QUOTENAME(OBJECT_SCHEMA_NAME(source_object_id)) + '.' + QUOTENAME(OBJECT_NAME(source_object_id))
        FROM cdc.change_tables;

    OPEN cdc_cur;
    FETCH NEXT FROM cdc_cur INTO @ct;
    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @sql = N'
            INSERT INTO #res (object_name, rows_found)
            SELECT ' + QUOTENAME(@ct, '''') + N', COUNT(*)
            FROM ' + @ct + N'
            WHERE customer_id = @cid
               OR full_name = @name
               OR email = @email
               OR phone = @phone;';
        EXEC sp_executesql @sql,
             N'@cid int, @name nvarchar(200), @email nvarchar(200), @phone nvarchar(200)',
             @cid = @cid, @name = @name, @email = @email, @phone = @phone;

        FETCH NEXT FROM cdc_cur INTO @ct;
    END
    CLOSE cdc_cur;
    DEALLOCATE cdc_cur;
END

/* 4. Any other base table in this database with matching column names */
DECLARE @tbl sysname, @sql2 nvarchar(max);
DECLARE tcur CURSOR LOCAL FAST_FORWARD FOR
    SELECT QUOTENAME(s.name) + '.' + QUOTENAME(t.name)
    FROM sys.tables t
    JOIN sys.schemas s ON s.schema_id = t.schema_id
    WHERE t.is_ms_shipped = 0
      AND t.name NOT IN ('customer','customer_history')
      AND t.name NOT LIKE 'dbo_customer_CT%';

OPEN tcur;
FETCH NEXT FROM tcur INTO @tbl;
WHILE @@FETCH_STATUS = 0
BEGIN
    DECLARE @pred nvarchar(max) = N'';
    IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(@tbl) AND name = 'customer_id')
        SET @pred = @pred + N'customer_id = @cid OR ';
    IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(@tbl) AND name = 'full_name')
        SET @pred = @pred + N'full_name = @name OR ';
    IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(@tbl) AND name = 'email')
        SET @pred = @pred + N'email = @email OR ';
    IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(@tbl) AND name = 'phone')
        SET @pred = @pred + N'phone = @phone OR ';

    IF LEN(@pred) > 0
    BEGIN
        SET @pred = LEFT(@pred, LEN(@pred) - 3);
        SET @sql2 = N'
            INSERT INTO #res (object_name, rows_found)
            SELECT ' + QUOTENAME(@tbl, '''') + N', COUNT(*)
            FROM ' + @tbl + N'
            WHERE ' + @pred + N';';
        EXEC sp_executesql @sql2,
             N'@cid int, @name nvarchar(200), @email nvarchar(200), @phone nvarchar(200)',
             @cid = @cid, @name = @name, @email = @email, @phone = @phone;
    END

    FETCH NEXT FROM tcur INTO @tbl;
END
CLOSE tcur;
DEALLOCATE tcur;

SELECT object_name, rows_found FROM #res ORDER BY object_name;
