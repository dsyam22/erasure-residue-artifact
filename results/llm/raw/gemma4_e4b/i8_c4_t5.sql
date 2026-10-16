WITH CheckResults AS (
    -- 1. Check the primary table where deletion occurred
    SELECT
        'dbo.customer' AS object_name,
        COUNT(*) AS rows_found
    FROM
        dbo.customer
    WHERE
        full_name = 'Subject_0000042' AND
        email = 'subject42@example.invalid' AND
        phone = '+1-555-0000042' AND
        -- Since customer_id was part of the PII and is an INT, we check it explicitly.
        CAST(customer_id AS NVARCHAR) = '42' 
),
AllObjects AS (
    -- List all objects checked to ensure every object name appears in the final result set
    SELECT 'dbo.customer' AS object_name
)
-- Join the list of objects with the actual counts, defaulting to 0 if no data is found for an object
SELECT
    A.object_name,
    ISNULL(C.rows_found, 0) AS rows_found
FROM
    AllObjects A
LEFT JOIN
    CheckResults C ON A.object_name = C.object_name;
