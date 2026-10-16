DECLARE @customer_id int = 42;
DECLARE @full_name nvarchar(255) = N'Subject_0000042';
DECLARE @email nvarchar(255) = N'subject42@example.invalid';
DECLARE @phone nvarchar(50) = N'+1-555-0000042';

CREATE TABLE #results (
    object_name nvarchar(255),
    rows_found bigint
);

-- Check dbo.customer
INSERT INTO #results (object_name, rows_found)
SELECT 
    N'dbo.customer',
    COUNT(*)
FROM dbo.customer
WHERE customer_id = @customer_id
   OR full_name = @full_name
   OR email = @email
   OR phone = @phone;

-- Check reporting.customer_replica
INSERT INTO #results (object_name, rows_found)
SELECT 
    N'reporting.customer_replica',
    COUNT(*)
FROM reporting.customer_replica
WHERE customer_id = @customer_id
   OR full_name = @full_name
   OR email = @email
   OR phone = @phone;

-- Check CDC change tables (if any exist for relevant tables)
IF EXISTS (SELECT 1 FROM sys.tables WHERE name = 'customer' AND is_tracked_by_cdc = 1)
BEGIN
    DECLARE @cdc_schema nvarchar(255) = 'cdc';
    DECLARE @cdc_table nvarchar(255) = 'dbo_customer_CT';
    
    IF EXISTS (SELECT 1 FROM sys.tables WHERE schema_id = SCHEMA_ID(@cdc_schema) AND name = @cdc_table)
    BEGIN
        DECLARE @sql nvarchar(max);
        SET @sql = N'
            INSERT INTO #results (object_name, rows_found)
            SELECT 
                N''' + @cdc_schema + N'.' + @cdc_table + N''',
                COUNT(*)
            FROM ' + QUOTENAME(@cdc_schema) + N'.' + QUOTENAME(@cdc_table) + N'
            WHERE customer_id = @customer_id
               OR full_name = @full_name
               OR email = @email
               OR phone = @phone;';
        EXEC sp_executesql @sql, N'@customer_id int, @full_name nvarchar(255), @email nvarchar(255), @phone nvarchar(50)', 
                           @customer_id, @full_name, @email, @phone;
    END
END

-- Check temporal history tables (if any exist)
IF EXISTS (SELECT 1 FROM sys.tables WHERE name = 'customer' AND temporal_type = 2)
BEGIN
    DECLARE @history_schema nvarchar(255);
    DECLARE @history_table nvarchar(255);
    
    SELECT TOP 1 
        @history_schema = SCHEMA_NAME(schema_id),
        @history_table = name
    FROM sys.tables 
    WHERE object_id = (SELECT history_table_id FROM sys.tables WHERE name = 'customer' AND temporal_type = 2);
    
    IF @history_table IS NOT NULL
    BEGIN
        SET @sql = N'
            INSERT INTO #results (object_name, rows_found)
            SELECT 
                N''' + @history_schema + N'.' + @history_table + N''',
                COUNT(*)
            FROM ' + QUOTENAME(@history_schema) + N'.' + QUOTENAME(@history_table) + N'
            WHERE customer_id = @customer_id
               OR full_name = @full_name
               OR email = @email
               OR phone = @phone;';
        EXEC sp_executesql @sql, N'@customer_id int, @full_name nvarchar(255), @email nvarchar(255), @phone nvarchar(50)', 
                           @customer_id, @full_name, @email, @phone;
    END
END

-- Select final results
SELECT object_name, rows_found
FROM #results
ORDER BY object_name;

DROP TABLE #results;
