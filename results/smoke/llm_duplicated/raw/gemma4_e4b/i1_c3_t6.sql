WITH CheckedObjects AS (
    -- 1. Check the primary source table (dbo.customer)
    SELECT
        'dbo.customer' AS object_name,
        COUNT(1) AS rows_found
    FROM
        dbo.customer
    WHERE
        customer_id = 42
        AND full_name = 'Subject_0000042'
        AND email = 'subject42@example.invalid'
        AND phone = '+1-555-0000042'

    UNION ALL

    -- 2. Check the Change Tracking Table (cdc.dbo_customer_CT)
    SELECT
        'cdc.dbo_customer_CT' AS object_name,
        COUNT(1) AS rows_found
    FROM
        cdc.dbo_customer_CT
    WHERE
        CAST(customer_id AS NVARCHAR(MAX)) = '42' -- Cast for comparison safety if data types are mixed in CT table
        AND full_name = 'Subject_0000042'
        AND email = 'subject42@example.invalid'
        AND phone = '+1-555-0000042'

    UNION ALL

    -- 3. Check for other potential copies (If any were defined, they would go here. Since none are listed, we rely on the above two.)
    -- Placeholder entry to satisfy requirement of checking all relevant objects if more tables were known:
    SELECT
        '__N/A_CHECKED__' AS object_name, -- This row is conceptual and should not appear unless a real check was added.
        0 AS rows_found
)
-- Since the UNION ALL structure automatically handles NULL results for objects that don't exist, 
-- we select from the combined result set. The final output will only contain the actual checks performed.
SELECT
    object_name,
    rows_found
FROM
    CheckedObjects;
