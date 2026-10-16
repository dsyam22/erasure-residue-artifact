WITH SearchResults AS (
    -- Check dbo.customer for the full set of personal data
    SELECT
        'dbo.customer' AS object_name,
        COUNT(T1.customer_id) AS rows_found
    FROM
        dbo.customer T1
    WHERE
        T1.full_name = 'Subject_0000042'
        AND T1.email = 'subject42@example.invalid'
        AND T1.phone = '+1-555-0000042'
        -- Note: We check against the specific ID as well, although it should be redundant 
        -- if all fields match, ensuring maximum coverage of the search criteria.
        AND T1.customer_id = 42
),
AllObjects AS (
    -- List all objects that must be checked to guarantee one row per object in the final result set.
    -- Since only dbo.customer was provided, we list it here. If other tables were known, they would be listed here.
    SELECT 'dbo.customer' AS ObjectName
)
-- Combine results: For every object listed (AllObjects), select the count found for that object.
SELECT 
    T2.ObjectName AS object_name,
    COALESCE(SR.rows_found, 0) AS rows_found
FROM 
    AllObjects T2
LEFT JOIN 
    SearchResults SR ON T2.ObjectName = 'dbo.customer';
