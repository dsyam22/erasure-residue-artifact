-- SCRIPT
DECLARE @results TABLE (object_name NVARCHAR(255), rows_found INT);

-- Check dbo.customer for the subject's phone number (column may not exist)
IF EXISTS (
    SELECT 1 
    FROM sys.columns c
    JOIN sys.tables t ON c.object_id = t.object_id
    JOIN sys.schemas s ON t.schema_id = s.schema_id
    WHERE s.name = 'dbo' 
      AND t.name = 'customer' 
      AND c.name = 'phone'
)
BEGIN
    INSERT INTO @results
    SELECT 'dbo.customer', COUNT(*)
    FROM dbo.customer
    WHERE customer_id = 42 
      AND phone = '+1-555-0000042';
END
ELSE
BEGIN
    INSERT INTO @results
    SELECT 'dbo.customer', 0;
END

SELECT object_name, rows_found FROM @results;
