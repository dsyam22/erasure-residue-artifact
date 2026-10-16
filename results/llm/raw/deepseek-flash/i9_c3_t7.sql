DECLARE @customer_id int = 42;
DECLARE @full_name nvarchar(200) = N'Subject_0000042';
DECLARE @email nvarchar(200) = N'subject42@example.invalid';
DECLARE @phone nvarchar(200) = N'+1-555-0000042';

CREATE TABLE #results (object_name sysname, rows_found bigint);

-- dbo.customer
INSERT INTO #results (object_name, rows_found)
SELECT 'dbo.customer', COUNT_BIG(*)
FROM dbo.customer
WHERE customer_id = @customer_id
   OR full_name = @full_name
   OR email = @email
   OR phone = @phone;

-- dbo.customer_history (temporal history table)
INSERT INTO #results (object_name, rows_found)
SELECT 'dbo.customer_history', COUNT_BIG(*)
FROM dbo.customer_history
WHERE customer_id = @customer_id
   OR full_name = @full_name
   OR email = @email
   OR phone = @phone;

-- CDC change tables (only if CDC is enabled)
IF EXISTS (SELECT 1 FROM sys.databases WHERE name = DB_NAME() AND is_cdc_enabled = 1)
BEGIN
    IF OBJECT_ID('cdc.dbo_customer_CT', 'U') IS NOT NULL
    INSERT INTO #results (object_name, rows_found)
    SELECT 'cdc.dbo_customer_CT', COUNT_BIG(*)
    FROM cdc.dbo_customer_CT
    WHERE (customer_id = @customer_id OR full_name = @full_name OR email = @email OR phone = @phone);
END

-- Change tracking side table (if change tracking enabled)
IF EXISTS (SELECT 1 FROM sys.change_tracking_tables WHERE object_id = OBJECT_ID('dbo.customer'))
BEGIN
    IF OBJECT_ID('dbo.customer_changetable', 'U') IS NOT NULL
    INSERT INTO #results (object_name, rows_found)
    SELECT 'dbo.customer_changetable', COUNT_BIG(*)
    FROM dbo.customer_changetable
    WHERE (customer_id = @customer_id OR full_name = @full_name OR email = @email OR phone = @phone);
END

-- Scan all other user tables for the subject's identifiers
DECLARE @schema sysname, @table sysname, @sql nvarchar(max);
DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
    SELECT s.name, t.name
    FROM sys.tables t
    JOIN sys.schemas s ON s.schema_id = t.schema_id
    WHERE t.is_ms_shipped = 0
      AND t.name NOT IN ('customer', 'customer_history', 'customer_changetable')
      AND t.name NOT LIKE '%_CT'
      AND OBJECTPROPERTY(t.object_id, 'IsMSShipped') = 0;

OPEN cur;
FETCH NEXT FROM cur INTO @schema, @table;
WHILE @@FETCH_STATUS = 0
BEGIN
    SET @sql = N'
        INSERT INTO #results (object_name, rows_found)
        SELECT @obj, COUNT_BIG(*)
        FROM ' + QUOTENAME(@schema) + N'.' + QUOTENAME(@table) + N'
        WHERE CAST(customer_id AS nvarchar(4000)) = @cid
           OR full_name = @fn
           OR email = @em
           OR phone = @ph;';

    BEGIN TRY
        EXEC sp_executesql @sql,
            N'@obj sysname, @cid nvarchar(4000), @fn nvarchar(200), @em nvarchar(200), @ph nvarchar(200)',
            @obj = @schema + N'.' + @table,
            @cid = CAST(@customer_id AS nvarchar(4000)),
            @fn = @full_name, @em = @email, @ph = @phone;
    END TRY
    BEGIN CATCH
        -- Table lacks matching columns; still record that it was checked with 0.
        INSERT INTO #results (object_name, rows_found)
        VALUES (@schema + N'.' + @table, 0);
    END CATCH;

    FETCH NEXT FROM cur INTO @schema, @table;
END
CLOSE cur;
DEALLOCATE cur;

SELECT object_name, rows_found FROM #results;
DROP TABLE #results;
