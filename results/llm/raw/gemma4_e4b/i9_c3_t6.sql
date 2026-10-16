SELECT object_name, rows_found FROM (
    -- Check the active table (dbo.customer) for residual data
    SELECT 
        'dbo.customer' AS object_name, 
        COUNT(1) AS rows_found
    FROM dbo.customer
    WHERE customer_id = 42
      AND full_name = 'Subject_0000042'

    UNION ALL

    -- Check the temporal history table (dbo.customer_history) for residual data
    SELECT 
        'dbo.customer_history' AS object_name, 
        COUNT(1) AS rows_found
    FROM dbo.customer_history
    WHERE customer_id = 42
      AND full_name = 'Subject_0000042'
) AS Results;
