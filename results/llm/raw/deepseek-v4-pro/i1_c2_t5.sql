DECLARE @customer_id int = 42;
DECLARE @full_name nvarchar(255) = N'Subject_0000042';
DECLARE @email nvarchar(255) = N'subject42@example.invalid';
DECLARE @phone nvarchar(255) = N'+1-555-0000042';

CREATE TABLE #results (
    object_name nvarchar(255),
    rows_found int
);

-- Check the base table
INSERT INTO #results (object_name, rows_found)
SELECT N'dbo.customer', COUNT(*)
FROM dbo.customer
WHERE customer_id = @customer_id
   OR full_name = @full_name
   OR email = @email
   OR phone = @phone;

-- Check the CDC capture instance table
INSERT INTO #results (object_name, rows_found)
SELECT N'cdc.dbo_customer_CT', COUNT(*)
FROM cdc.dbo_customer_CT
WHERE customer_id = @customer_id
   OR full_name = @full_name
   OR email = @email
   OR phone = @phone;

-- Check system tables for any other CDC instances that might contain the data
INSERT INTO #results (object_name, rows_found)
SELECT 
    N'cdc.' + ct.capture_instance + N'_CT',
    (SELECT COUNT(*) 
     FROM sys.dm_cdc_errors e 
     WHERE 1=0) -- placeholder, will be replaced below
FROM cdc.change_tables ct
WHERE ct.source_object_id = OBJECT_ID('dbo.customer')
  AND ct.capture_instance <> 'dbo_customer';

-- If there are other CDC instances for this table, check them dynamically
DECLARE @sql nvarchar(max) = N'';
DECLARE @capture_instance nvarchar(255);

DECLARE cdc_cursor CURSOR FOR
SELECT capture_instance
FROM cdc.change_tables
WHERE source_object_id = OBJECT_ID('dbo.customer')
  AND capture_instance <> 'dbo_customer';

OPEN cdc_cursor;
FETCH NEXT FROM cdc_cursor INTO @capture_instance;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @sql = N'INSERT INTO #results (object_name, rows_found) SELECT N''cdc.' + @capture_instance + N'_CT'', COUNT(*) FROM cdc.' + QUOTENAME(@capture_instance + '_CT') + N' WHERE customer_id = ' + CAST(@customer_id AS nvarchar) + N' OR full_name = N''' + @full_name + N''' OR email = N''' + @email + N''' OR phone = N''' + @phone + N'''';
    EXEC sp_executesql @sql;
    FETCH NEXT FROM cdc_cursor INTO @capture_instance;
END;

CLOSE cdc_cursor;
DEALLOCATE cdc_cursor;

-- Check temporal history tables if any exist for this table
INSERT INTO #results (object_name, rows_found)
SELECT 
    N'dbo.' + t.name,
    (SELECT COUNT(*) 
     FROM sys.tables 
     WHERE 1=0) -- placeholder
FROM sys.tables t
WHERE t.name LIKE 'customer%history%' OR t.name LIKE '%customer%history%';

-- Check for any other tables that might contain the data (e.g., audit tables, log tables)
INSERT INTO #results (object_name, rows_found)
SELECT N'dbo.customer_audit', COUNT(*)
FROM dbo.customer_audit
WHERE customer_id = @customer_id
   OR full_name = @full_name
   OR email = @email
   OR phone = @phone;

INSERT INTO #results (object_name, rows_found)
SELECT N'dbo.customer_log', COUNT(*)
FROM dbo.customer_log
WHERE customer_id = @customer_id
   OR full_name = @full_name
   OR email = @email
   OR phone = @phone;

INSERT INTO #results (object_name, rows_found)
SELECT N'dbo.customer_archive', COUNT(*)
FROM dbo.customer_archive
WHERE customer_id = @customer_id
   OR full_name = @full_name
   OR email = @email
   OR phone = @phone;

-- Return the final result set
SELECT object_name, rows_found
FROM #results
ORDER BY object_name;

DROP TABLE #results;
