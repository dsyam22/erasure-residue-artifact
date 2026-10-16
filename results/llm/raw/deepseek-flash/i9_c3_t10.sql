/* Read-only verification of residual personal data for customer_id 42 */
DECLARE @cid int = 42;
DECLARE @name nvarchar(200) = N'Subject_0000042';
DECLARE @email nvarchar(320) = N'subject42@example.invalid';
DECLARE @phone nvarchar(50) = N'+1-555-0000042';

CREATE TABLE #results (object_name sysname, rows_found bigint);

/* 1. Current table */
INSERT INTO #results (object_name, rows_found)
SELECT N'dbo.customer', COUNT_BIG(*)
FROM dbo.customer
WHERE customer_id = @cid
   OR full_name = @name
   OR email = @email
   OR phone = @phone;

/* 2. Temporal history table */
INSERT INTO #results (object_name, rows_found)
SELECT N'dbo.customer_history', COUNT_BIG(*)
FROM dbo.customer_history
WHERE customer_id = @cid
   OR full_name = @name
   OR email = @email
   OR phone = @phone;

/* 3. CDC change tables, if CDC is enabled and capture instances exist */
IF EXISTS (SELECT 1 FROM sys.tables WHERE name = 'customer' AND schema_id = SCHEMA_ID('dbo') AND is_tracked_by_cdc = 1)
BEGIN
    DECLARE @capture_instance sysname;
    DECLARE @cdc_schema sysname;
    DECLARE @cdc_table sysname;
    DECLARE @sql nvarchar(max);

    DECLARE cdc_cur CURSOR LOCAL FAST_FORWARD FOR
        SELECT capture_instance
        FROM cdc.change_tables
        WHERE source_object_id = OBJECT_ID(N'dbo.customer');

    OPEN cdc_cur;
    FETCH NEXT FROM cdc_cur INTO @capture_instance;
    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @cdc_schema = N'cdc';
        SET @cdc_table = @capture_instance + N'_CT';
        SET @sql = N'INSERT INTO #results (object_name, rows_found)
                     SELECT N''cdc.' + @cdc_table + N''', COUNT_BIG(*)
                     FROM cdc.' + QUOTENAME(@cdc_table) + N'
                     WHERE customer_id = @cid
                        OR full_name = @name
                        OR email = @email
                        OR phone = @phone;';
        EXEC sp_executesql @sql,
            N'@cid int, @name nvarchar(200), @email nvarchar(320), @phone nvarchar(50)',
            @cid = @cid, @name = @name, @email = @email, @phone = @phone;
        FETCH NEXT FROM cdc_cur INTO @capture_instance;
    END
    CLOSE cdc_cur;
    DEALLOCATE cdc_cur;
END

/* 4. Change tracking side table, if enabled */
IF EXISTS (SELECT 1 FROM sys.change_tracking_tables WHERE object_id = OBJECT_ID(N'dbo.customer'))
BEGIN
    INSERT INTO #results (object_name, rows_found)
    SELECT N'sys.dm_tran_commit_table (change tracking)', COUNT_BIG(*)
    FROM sys.dm_tran_commit_table ct
    WHERE EXISTS (
        SELECT 1
        FROM CHANGETABLE(CHANGES dbo.customer, 0) AS ch
        WHERE ch.customer_id = @cid
    );
END
ELSE
BEGIN
    INSERT INTO #results (object_name, rows_found)
    SELECT N'sys.dm_tran_commit_table (change tracking)', 0;
END

/* 5. Any other table in the database that might contain the values (defensive sweep) */
DECLARE @tbl sysname, @sch sysname, @col sysname, @sweep nvarchar(max);
DECLARE sweep_cur CURSOR LOCAL FAST_FORWARD FOR
    SELECT s.name, t.name, c.name
    FROM sys.columns c
    JOIN sys.tables t ON t.object_id = c.object_id
    JOIN sys.schemas s ON s.schema_id = t.schema_id
    WHERE c.system_type_id IN (167, 231, 239, 175) /* varchar, nvarchar, nchar, char */
      AND t.is_ms_shipped = 0
      AND NOT (s.name = 'dbo' AND t.name IN ('customer', 'customer_history'))
      AND NOT (s.name = 'cdc')
      AND t.name NOT LIKE '%_CT';

OPEN sweep_cur;
FETCH NEXT FROM sweep_cur INTO @sch, @tbl, @col;
WHILE @@FETCH_STATUS = 0
BEGIN
    SET @sweep = N'INSERT INTO #results (object_name, rows_found)
                   SELECT N''' + @sch + N'.' + @tbl + N''', COUNT_BIG(*)
                   FROM ' + QUOTENAME(@sch) + N'.' + QUOTENAME(@tbl) + N'
                   WHERE ' + QUOTENAME(@col) + N' IN (@name, @email, @phone);';
    BEGIN TRY
        EXEC sp_executesql @sweep,
            N'@name nvarchar(200), @email nvarchar(320), @phone nvarchar(50)',
            @name = @name, @email = @email, @phone = @phone;
    END TRY
    BEGIN CATCH
        /* ignore inaccessible objects */
    END CATCH
    FETCH NEXT FROM sweep_cur INTO @sch, @tbl, @col;
END
CLOSE sweep_cur;
DEALLOCATE sweep_cur;

SELECT object_name, rows_found FROM #results ORDER BY object_name;
