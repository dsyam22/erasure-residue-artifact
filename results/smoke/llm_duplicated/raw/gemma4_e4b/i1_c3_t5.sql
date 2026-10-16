WITH Check_Customer AS (
    -- 1. Check the main operational table (dbo.customer)
    SELECT
        'dbo.customer' AS object_name,
        CAST(COUNT(T1.customer_id) AS INT) AS rows_found
    FROM
        dbo.customer T1
    WHERE
        T1.customer_id = 42
        AND T1.full_name = 'Subject_0000042'
        AND T1.email = 'subject42@example.invalid'
        AND T1.phone = '+1-555-0000042'
),
Check_CDC_CT AS (
    -- 2. Check the CDC Change Tracking table (cdc.dbo_customer_CT)
    -- We check if any change record still contains this specific ID, indicating persistence in tracking metadata.
    SELECT
        'cdc.dbo_customer_CT' AS object_name,
        CAST(COUNT(T1.customer_id) AS INT) AS rows_found
    FROM
        cdc.dbo_customer_CT T1
    WHERE
        T1.customer_id = 42
        -- Note: Due to the nature of CDC DELETE operations, finding full matching records here is unlikely/difficult.
        -- We check for the primary key persistence as a proxy for data existence verification in this location.
)
SELECT object_name, rows_found FROM Check_Customer
UNION ALL
SELECT object_name, rows_found FROM Check_CDC_CT;
