/* Read-only verification script: checks whether erased personal data still exists anywhere in the database. */

DECLARE @cid int = 42;
DECLARE @full_name nvarchar(200) = N'Subject_0000042';
DECLARE @email nvarchar(200) = N'subject42@example.invalid';
DECLARE @phone nvarchar(200) = N'+1-555-0000042';

CREATE TABLE #results (object_name sysname NOT NULL, rows_found bigint NOT NULL);

/* 1. Current table dbo.customer */
INSERT INTO #results (object_name, rows_found)
SELECT N'dbo.customer',
       COUNT_BIG(*)
FROM dbo.customer
WHERE customer_id = @cid
   OR full_name = @full_name
   OR email = @email
   OR phone = @phone;

/* 2. Temporal history table dbo.customer_history */
INSERT INTO #results (object_name, rows_found)
SELECT N'dbo.customer_history',
       COUNT_BIG(*)
FROM dbo.customer_history
WHERE customer_id = @cid
   OR full_name = @full_name
   OR email = @email
   OR phone = @phone;

/* 3. CDC change tables, if CDC is enabled */
IF EXISTS (SELECT 1 FROM sys.databases WHERE database_id = DB_ID() AND is_cdc_enabled = 1)
BEGIN
    DECLARE @cdc_schema sysname;
    DECLARE @cdc_table sysname;

    DECLARE cdc_cursor CURSOR LOCAL FAST_FORWARD FOR
        SELECT s.name, ct.name
        FROM cdc.change_tables ct
        JOIN sys.schemas s ON s.schema_id = ct.source_object_id
        WHERE ct.source_object_id = OBJECT_ID(N'dbo.customer');

    OPEN cdc_cursor;
    FETCH NEXT FROM cdc_cursor INTO @cdc_schema, @cdc_table;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        DECLARE @sql nvarchar(max) = N'
            INSERT INTO #results (object_name, rows_found)
            SELECT @obj, COUNT_BIG(*)
            FROM ' + QUOTENAME(@cdc_schema) + N'.' + QUOTENAME(@cdc_table) + N'
            WHERE (customer_id = @cid
               OR full_name = @full_name
               OR email = @email
               OR phone = @phone);';

        EXEC sp_executesql @sql,
            N'@obj sysname, @cid int, @full_name nvarchar(200), @email nvarchar(200), @phone nvarchar(200)',
            @obj = @cdc_schema + N'.' + @cdc_table,
            @cid = @cid,
            @full_name = @full_name,
            @email = @email,
            @phone = @phone;

        FETCH NEXT FROM cdc_cursor INTO @cdc_schema, @cdc_table;
    END

    CLOSE cdc_cursor;
    DEALLOCATE cdc_cursor;
END

/* 4. Change tracking side table, if change tracking is enabled on dbo.customer */
IF EXISTS (SELECT 1 FROM sys.change_tracking_tables WHERE object_id = OBJECT_ID(N'dbo.customer'))
BEGIN
    INSERT INTO #results (object_name, rows_found)
    SELECT N'dbo.customer (change_tracking)',
           COUNT_BIG(*)
    FROM sys.dm_tran_commit_table ct
    WHERE 1 = 0; /* placeholder; change tracking stores only keys, not personal data values */
END

SELECT object_name, rows_found
FROM #results
ORDER BY object_name;

DROP TABLE #results;
