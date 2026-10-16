SELECT object_name, rows_found FROM (
    -- Check dbo.customer
    SELECT 
        'dbo.customer' AS object_name, 
        COUNT(1) AS rows_found
    FROM dbo.customer c
    WHERE c.customer_id = 42
      AND c.full_name = 'Subject_0000042'
      AND c.email = 'subject42@example.invalid'
      AND c.phone = '+1-555-0000042'

    UNION ALL

    -- Check reporting.customer_replica
    SELECT 
        'reporting.customer_replica' AS object_name, 
        COUNT(1) AS rows_found
    FROM reporting.customer_replica r
    WHERE r.customer_id = 42
      AND r.full_name = 'Subject_0000042'
      AND r.email = 'subject42@example.invalid'
      AND r.phone = '+1-555-0000042'

) AS VerificationResults;
