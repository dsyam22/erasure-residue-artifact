SET NOCOUNT ON;

DECLARE @customer_id int = 42;
DECLARE @full_name nvarchar(255) = N'Subject_0000042';
DECLARE @email nvarchar(255) = N'subject42@example.invalid';
DECLARE @phone nvarchar(255) = N'+1-555-0000042';

CREATE TABLE #results (
    object_name nvarchar(255),
    rows_found int
);

-- Check base table dbo.customer
INSERT INTO #results (object_name, rows_found)
SELECT N'dbo.customer', COUNT(*)
FROM dbo.customer
WHERE customer_id = @customer_id
   OR full_name = @full_name
   OR email = @email
   OR phone = @phone;

-- Check CDC capture instance
IF EXISTS (SELECT 1 FROM sys.tables t
           JOIN sys.schemas s ON t.schema_id = s.schema_id
           WHERE s.name = N'cdc' AND t.name = N'dbo_customer_CT')
BEGIN
    INSERT INTO #results (object_name, rows_found)
    SELECT N'cdc.dbo_customer_CT', COUNT(*)
    FROM cdc.dbo_customer_CT
    WHERE customer_id = @customer_id
       OR full_name = @full_name
       OR email = @email
       OR phone = @phone;
END
ELSE
BEGIN
    INSERT INTO #results (object_name, rows_found)
    SELECT N'cdc.dbo_customer_CT', 0;
END

-- Check any other tables that might contain the data (e.g., audit tables, history tables)
-- Since only dbo.customer is listed, we only check that and CDC.
-- If additional tables existed, they would be added here.

SELECT object_name, rows_found
FROM #results
ORDER BY object_name;

DROP TABLE #results;
