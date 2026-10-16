WITH ObjectCheck AS (
    -- Check dbo.customer for any residual data matching the subject's identifiers
    SELECT
        CAST('dbo.customer' AS nvarchar) AS object_name,
        COUNT(1) AS rows_found
    FROM
        dbo.customer
    WHERE
        customer_id = 42 OR
        full_name = 'Subject_0000042' OR
        email = 'subject42@example.invalid' OR
        phone = '+1-555-0000042'
)
SELECT
    object_name,
    rows_found
FROM
    ObjectCheck;
