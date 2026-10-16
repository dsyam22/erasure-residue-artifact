SELECT
    'dbo.customer' AS object_name,
    (
        -- Since the phone number column has been dropped, we must check if the target string 
        -- appears in any of the remaining columns (full_name or email) or if it was accidentally stored elsewhere.
        SELECT COUNT(T.customer_id)
        FROM dbo.customer T
        WHERE 
            T.full_name LIKE '%' + '+1-555-0000042' + '%' OR
            T.email LIKE '%' + '+1-555-0000042' + '%'
    ) AS rows_found;
