DECLARE @customer_id INT = 42;
DECLARE @phone NVARCHAR(50) = '+1-555-0000042';

CREATE TABLE #results (
    object_name NVARCHAR(255),
    rows_found INT
);

-- Check current dbo.customer table (phone column should no longer exist)
IF EXISTS (
    SELECT 1
    FROM sys.columns
    WHERE object_id = OBJECT_ID('dbo.customer')
      AND name = 'phone'
)
BEGIN
    DECLARE @sql NVARCHAR(MAX) = N'
        INSERT INTO #results (object_name, rows_found)
        SELECT ''dbo.customer'', COUNT(*)
        FROM dbo.customer
        WHERE customer_id = @customer_id
          AND phone = @phone';
    EXEC sp_executesql @sql, N'@customer_id INT, @phone NVARCHAR(50)', @customer_id, @phone;
END
ELSE
BEGIN
    INSERT INTO #results (object_name, rows_found)
    SELECT 'dbo.customer', 0;
END

-- Check CDC capture instance table (if it exists)
IF EXISTS (
    SELECT 1
    FROM sys.tables t
    JOIN sys.schemas s ON t.schema_id = s.schema_id
    WHERE s.name = 'cdc'
      AND t.name = 'dbo_customer_CT'
)
BEGIN
    IF EXISTS (
        SELECT 1
        FROM sys.columns
        WHERE object_id = OBJECT_ID('cdc.dbo_customer_CT')
          AND name = 'phone'
    )
    BEGIN
        DECLARE @cdc_sql NVARCHAR(MAX) = N'
            INSERT INTO #results (object_name, rows_found)
            SELECT ''cdc.dbo_customer_CT'', COUNT(*)
            FROM cdc.dbo_customer_CT
            WHERE customer_id = @customer_id
              AND phone = @phone';
        EXEC sp_executesql @cdc_sql, N'@customer_id INT, @phone NVARCHAR(50)', @customer_id, @phone;
    END
    ELSE
    BEGIN
        INSERT INTO #results (object_name, rows_found)
        SELECT 'cdc.dbo_customer_CT', 0;
    END
END
ELSE
BEGIN
    INSERT INTO #results (object_name, rows_found)
    SELECT 'cdc.dbo_customer_CT', 0;
END

-- Return final result set
SELECT object_name, rows_found
FROM #results
ORDER BY object_name;

DROP TABLE #results;
