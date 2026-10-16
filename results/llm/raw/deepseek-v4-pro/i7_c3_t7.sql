DECLARE @customer_id INT = 42;
DECLARE @full_name NVARCHAR(255) = N'Subject_0000042';
DECLARE @email NVARCHAR(255) = N'subject42@example.invalid';
DECLARE @phone NVARCHAR(255) = N'+1-555-0000042';

-- Temporary table to hold results
CREATE TABLE #results (
    object_name NVARCHAR(255),
    rows_found INT
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

-- Since CDC is disabled and tables are non-temporal,
-- there are no change tables or history tables to check.
-- However, we can still check for any CDC-related objects if they exist
-- (they should not, but we include them for completeness with 0 rows).

-- Check for CDC change tables (if any exist)
IF EXISTS (SELECT 1 FROM sys.tables WHERE name LIKE '%_CT' AND is_tracked_by_cdc = 1)
BEGIN
    DECLARE @ct_table NVARCHAR(255);
    DECLARE ct_cursor CURSOR FOR
        SELECT QUOTENAME(SCHEMA_NAME(schema_id)) + '.' + QUOTENAME(name)
        FROM sys.tables
        WHERE name LIKE '%_CT' AND is_tracked_by_cdc = 1;

    OPEN ct_cursor;
    FETCH NEXT FROM ct_cursor INTO @ct_table;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        DECLARE @sql NVARCHAR(MAX);
        SET @sql = N'
            INSERT INTO #results (object_name, rows_found)
            SELECT ''' + @ct_table + ''', COUNT(*)
            FROM ' + @ct_table + '
            WHERE customer_id = @customer_id
               OR full_name = @full_name
               OR email = @email
               OR phone = @phone;';
        EXEC sp_executesql @sql, N'@customer_id INT, @full_name NVARCHAR(255), @email NVARCHAR(255), @phone NVARCHAR(255)',
                           @customer_id, @full_name, @email, @phone;
        FETCH NEXT FROM ct_cursor INTO @ct_table;
    END

    CLOSE ct_cursor;
    DEALLOCATE ct_cursor;
END
ELSE
BEGIN
    -- No CDC change tables exist
    INSERT INTO #results (object_name, rows_found)
    SELECT N'cdc_change_tables', 0;
END

-- Check for temporal history tables (if any exist)
IF EXISTS (SELECT 1 FROM sys.tables WHERE temporal_type = 1)
BEGIN
    DECLARE @hist_table NVARCHAR(255);
    DECLARE hist_cursor CURSOR FOR
        SELECT QUOTENAME(SCHEMA_NAME(schema_id)) + '.' + QUOTENAME(name)
        FROM sys.tables
        WHERE temporal_type = 1;

    OPEN hist_cursor;
    FETCH NEXT FROM hist_cursor INTO @hist_table;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @sql = N'
            INSERT INTO #results (object_name, rows_found)
            SELECT ''' + @hist_table + ''', COUNT(*)
            FROM ' + @hist_table + '
            WHERE customer_id = @customer_id
               OR full_name = @full_name
               OR email = @email
               OR phone = @phone;';
        EXEC sp_executesql @sql, N'@customer_id INT, @full_name NVARCHAR(255), @email NVARCHAR(255), @phone NVARCHAR(255)',
                           @customer_id, @full_name, @email, @phone;
        FETCH NEXT FROM hist_cursor INTO @hist_table;
    END

    CLOSE hist_cursor;
    DEALLOCATE hist_cursor;
END
ELSE
BEGIN
    -- No temporal history tables exist
    INSERT INTO #results (object_name, rows_found)
    SELECT N'temporal_history_tables', 0;
END

-- Return final result set
SELECT object_name, rows_found
FROM #results
ORDER BY object_name;

DROP TABLE #results;
