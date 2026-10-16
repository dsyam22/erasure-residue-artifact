/* Read-only verification of residual personal data for Subject_0000042 */
SET NOCOUNT ON;

DECLARE @cid int = 42;
DECLARE @full nvarchar(200) = N'Subject_0000042';
DECLARE @email nvarchar(320) = N'subject42@example.invalid';
DECLARE @phone nvarchar(50) = N'+1-555-0000042';

/* Result collection table */
CREATE TABLE #res (object_name sysname, rows_found bigint);

/* Helper: match on any of the identifying values */
DECLARE @match nvarchar(max);

/* 1) dbo.customer */
INSERT INTO #res (object_name, rows_found)
SELECT 'dbo.customer', COUNT(*)
FROM dbo.customer
WHERE customer_id = @cid
   OR full_name = @full
   OR email = @email
   OR phone = @phone;

/* 2) reporting.customer_replica */
INSERT INTO #res (object_name, rows_found)
SELECT 'reporting.customer_replica', COUNT(*)
FROM reporting.customer_replica
WHERE customer_id = @cid
   OR full_name = @full
   OR email = @email
   OR phone = @phone;

/* 3) Any temporal history tables for these tables (none configured, but check dynamically) */
DECLARE @sql nvarchar(max) = N'';

;WITH t AS (
    SELECT s.name AS sch, t.name AS tbl, t.history_table_id
    FROM sys.tables t
    JOIN sys.schemas s ON s.schema_id = t.schema_id
    WHERE t.temporal_type = 1
      AND t.object_id IN (
          OBJECT_ID('dbo.customer'),
          OBJECT_ID('reporting.customer_replica')
      )
)
SELECT @sql = @sql + N'
INSERT INTO #res (object_name, rows_found)
SELECT ''' + sch + N'.' + OBJECT_NAME(history_table_id) + N''', COUNT(*)
FROM ' + QUOTENAME(sch) + N'.' + QUOTENAME(OBJECT_NAME(history_table_id)) + N'
WHERE customer_id = @cid OR full_name = @full OR email = @email OR phone = @phone;'
FROM t;

IF @sql <> N''
BEGIN
    SET @sql = N'DECLARE @cid int = 42, @full nvarchar(200) = N''Subject_0000042'', @email nvarchar(320) = N''subject42@example.invalid'', @phone nvarchar(50) = N''+1-555-0000042'';' + @sql;
    EXEC sp_executesql @sql;
END

/* 4) Any CDC change tables for these tables (cdc_enabled=0, but verify dynamically) */
DECLARE @cdc nvarchar(max) = N'';

IF EXISTS (SELECT 1 FROM sys.databases WHERE name = DB_NAME() AND is_cdc_enabled = 1)
BEGIN
    ;WITH c AS (
        SELECT s.name AS sch, ct.capture_instance, ct.source_object_id
        FROM cdc.change_tables ct
        JOIN sys.schemas s ON s.schema_id = ct.source_schema_id
        WHERE ct.source_object_id IN (
            OBJECT_ID('dbo.customer'),
            OBJECT_ID('reporting.customer_replica')
        )
    )
    SELECT @cdc = @cdc + N'
INSERT INTO #res (object_name, rows_found)
SELECT ''cdc.'' + ''' + capture_instance + N''', COUNT(*)
FROM cdc.' + QUOTENAME(capture_instance) + N'
WHERE customer_id = @cid OR full_name = @full OR email = @email OR phone = @phone;'
    FROM c;

    IF @cdc <> N''
    BEGIN
        SET @cdc = N'DECLARE @cid int = 42, @full nvarchar(200) = N''Subject_0000042'', @email nvarchar(320) = N''subject42@example.invalid'', @phone nvarchar(50) = N''+1-555-0000042'';' + @cdc;
        EXEC sp_executesql @cdc;
    END
END

/* 5) Any change-tracking side tables for these tables */
DECLARE @ct nvarchar(max) = N'';

;WITH ct AS (
    SELECT s.name AS sch, t.name AS tbl
    FROM sys.change_tracking_tables ct
    JOIN sys.tables t ON t.object_id = ct.object_id
    JOIN sys.schemas s ON s.schema_id = t.schema_id
    WHERE t.object_id IN (
        OBJECT_ID('dbo.customer'),
        OBJECT_ID('reporting.customer_replica')
    )
)
SELECT @ct = @ct + N'
INSERT INTO #res (object_name, rows_found)
SELECT ''' + sch + N'.' + tbl + N' (change_tracking)'', COUNT(*)
FROM ' + QUOTENAME(sch) + N'.' + QUOTENAME(tbl) + N'
WHERE customer_id = @cid OR full_name = @full OR email = @email OR phone = @phone;'
FROM ct;

IF @ct <> N''
BEGIN
    SET @ct = N'DECLARE @cid int = 42, @full nvarchar(200) = N''Subject_0000042'', @email nvarchar(320) = N''subject42@example.invalid'', @phone nvarchar(50) = N''+1-555-0000042'';' + @ct;
    EXEC sp_executesql @ct;
END

/* Final single result set */
SELECT object_name, rows_found
FROM #res
ORDER BY object_name;

DROP TABLE #res;
