DECLARE @customer_id INT = 42;
DECLARE @full_name NVARCHAR(255) = N'Subject_0000042';
DECLARE @email NVARCHAR(255) = N'subject42@example.invalid';
DECLARE @phone NVARCHAR(255) = N'+1-555-0000042';

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

-- Check change data capture (CDC) change tables if enabled
IF EXISTS (SELECT 1 FROM sys.change_tracking_tables WHERE object_id = OBJECT_ID(N'dbo.customer'))
BEGIN
    DECLARE @ct_sql NVARCHAR(MAX) = N'';
    SELECT @ct_sql = @ct_sql + 
        N'INSERT INTO #results (object_name, rows_found) ' +
        N'SELECT N''' + QUOTENAME(s.name) + N'.' + QUOTENAME(t.name) + N''', COUNT(*) ' +
        N'FROM ' + QUOTENAME(s.name) + N'.' + QUOTENAME(t.name) + N' ct ' +
        N'INNER JOIN dbo.customer c ON ct.customer_id = c.customer_id ' +
        N'WHERE c.customer_id = @customer_id ' +
        N'   OR c.full_name = @full_name ' +
        N'   OR c.email = @email ' +
        N'   OR c.phone = @phone; '
    FROM sys.change_tracking_tables ctt
    INNER JOIN sys.tables t ON ctt.object_id = t.object_id
    INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
    WHERE ctt.object_id = OBJECT_ID(N'dbo.customer');

    IF @ct_sql <> N''
    BEGIN
        EXEC sp_executesql @ct_sql, N'@customer_id INT, @full_name NVARCHAR(255), @email NVARCHAR(255), @phone NVARCHAR(255)',
            @customer_id, @full_name, @email, @phone;
    END
END

-- Check temporal history tables if applicable (none for these tables, but include for completeness)
IF EXISTS (SELECT 1 FROM sys.tables WHERE temporal_type = 2 AND object_id = OBJECT_ID(N'dbo.customer'))
BEGIN
    INSERT INTO #results (object_name, rows_found)
    SELECT 
        N'dbo.customer_history',
        COUNT(*)
    FROM dbo.customer_history
    WHERE customer_id = @customer_id
       OR full_name = @full_name
       OR email = @email
       OR phone = @phone;
END

IF EXISTS (SELECT 1 FROM sys.tables WHERE temporal_type = 2 AND object_id = OBJECT_ID(N'reporting.customer_replica'))
BEGIN
    INSERT INTO #results (object_name, rows_found)
    SELECT 
        N'reporting.customer_replica_history',
        COUNT(*)
    FROM reporting.customer_replica_history
    WHERE customer_id = @customer_id
       OR full_name = @full_name
       OR email = @email
       OR phone = @phone;
END

-- Ensure we have at least one row for each checked object, even if no rows found
IF NOT EXISTS (SELECT 1 FROM #results WHERE object_name = N'dbo.customer')
    INSERT INTO #results VALUES (N'dbo.customer', 0);
IF NOT EXISTS (SELECT 1 FROM #results WHERE object_name = N'reporting.customer_replica')
    INSERT INTO #results VALUES (N'reporting.customer_replica', 0);

SELECT object_name, rows_found
FROM #results
ORDER BY object_name;

DROP TABLE #results;
