SELECT object_name, rows_found FROM (
    -- Check 1: The primary table itself (should be 0 after DELETE)
    SELECT 'dbo.customer' AS object_name, COUNT(customer_id) AS rows_found
    FROM dbo.customer
    WHERE customer_id = 42 
      AND full_name = N'Subject_0000042' 
      AND email = N'subject42@example.invalid' 
      AND phone = N'+1-555-0000042'

    UNION ALL

    -- Check 2: The Change Data Capture (CDC) table (where the record exists until cleanup)
    SELECT 'cdc.dbo_customer_CT' AS object_name, COUNT(customer_id) AS rows_found
    FROM cdc.dbo_customer_CT
    WHERE customer_id = 42 
      AND full_name = N'Subject_0000042' 
      AND email = N'subject42@example.invalid' 
      AND phone = N'+1-555-0000042'

) AS SearchResults;
