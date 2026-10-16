SET NOCOUNT ON;

IF OBJECT_ID('tempdb..#Results') IS NOT NULL
    DROP TABLE #Results;

CREATE TABLE #Results (
    object_name nvarchar(257),
    rows_found bigint
);

-- Check main table
INSERT INTO #Results (object_name, rows_found)
SELECT N'dbo.customer', COUNT(*)
FROM dbo.customer
WHERE customer_id = 42
   OR full_name = N'Subject_0000042'
   OR email = N'subject42@example.invalid'
   OR phone = N'+1-555-0000042';

-- Check temporal history table
INSERT INTO #Results (object_name, rows_found)
SELECT N'dbo.customer_history', COUNT(*)
FROM dbo.customer_history
WHERE customer_id = 42
   OR full_name = N'Subject_0000042'
   OR email = N'subject42@example.invalid'
   OR phone = N'+1-555-0000042';

-- Check CDC capture instance (only if CDC is enabled on database and table)
IF EXISTS (
    SELECT 1
    FROM sys.databases
    WHERE name = DB_NAME() AND is_cdc_enabled = 1
)
BEGIN
    IF EXISTS (
        SELECT 1
        FROM sys.tables t
        JOIN sys.schemas s ON t.schema_id = s.schema_id
        WHERE s.name = N'dbo' AND t.name = N'customer' AND t.is_tracked_by_cdc = 1
    )
    BEGIN
        INSERT INTO #Results (object_name, rows_found)
        SELECT N'cdc.dbo_customer_CT', COUNT(*)
        FROM cdc.dbo_customer_CT
        WHERE customer_id = 42
           OR full_name = N'Subject_0000042'
           OR email = N'subject42@example.invalid'
           OR phone = N'+1-555-0000042';
    END
END

-- Return final result set
SELECT object_name, rows_found
FROM #Results
ORDER BY object_name;

DROP TABLE #Results;
