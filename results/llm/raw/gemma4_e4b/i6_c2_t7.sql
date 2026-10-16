SELECT 
    'dbo.customer' AS object_name, 
    0 AS rows_found

UNION ALL

SELECT 
    'cdc.dbo_customer_CT', 
    ISNULL(T.row_count, 0)

FROM (
    -- Check the Change Tracking table for residual phone data
    SELECT COUNT(*) AS row_count
    FROM cdc.dbo_customer_CT
    WHERE customer_id = 42 AND phone = '+1-555-0000042'
) T;
