WITH CheckResults AS
(
    -- 1. Primary Customer Table (dbo.customer)
    SELECT
        'dbo.customer' AS object_name,
        CAST(COUNT(customer_id) AS INT) AS rows_found
    FROM
        dbo.customer WITH (NOLOCK)
    WHERE
        customer_id = 42

    UNION ALL

    -- 2. CDC Change Table (cdc.dbo_customer_CT)
    SELECT
        'cdc.dbo_customer_CT' AS object_name,
        CAST(COUNT(customer_id) AS INT) AS rows_found
    FROM
        cdc.dbo_customer_CT WITH (NOLOCK)
    WHERE
        customer_id = 42

    UNION ALL

    -- Since the table is NON_TEMPORAL and no downstream copies were specified, 
    -- we only check structures related to the provided data model. 
    -- We must include a placeholder for completeness if future checks required it, 
    -- but based strictly on the available objects (customer, cdc.dbo_customer_CT), 
    -- these two covers all explicit persistence points.
    SELECT
        'N/A (No other specified locations found)' AS object_name,
        CAST(0 AS INT) AS rows_found
)
-- Select the final required structure: one row per checked object
SELECT
    object_name,
    rows_found
FROM
    CheckResults
ORDER BY
    CASE 
        WHEN object_name = 'dbo.customer' THEN 1
        WHEN object_name = 'cdc.dbo_customer_CT' THEN 2
        ELSE 3
    END;
