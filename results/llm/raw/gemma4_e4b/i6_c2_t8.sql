SELECT 'dbo.customer' AS object_name, 0 AS rows_found
UNION ALL
SELECT 'cdc.dbo_customer_CT', ISNULL(
    (
        SELECT COUNT(*)
        FROM cdc.dbo_customer_CT
        WHERE customer_id = 42 AND phone IS NOT NULL
    ), 0
);
