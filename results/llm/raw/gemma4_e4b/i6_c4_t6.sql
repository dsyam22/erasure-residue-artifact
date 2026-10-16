SELECT 
    CAST('dbo.customer' AS NVARCHAR(128)) AS object_name,
    -- Check if the specific phone number pattern exists in any of the remaining columns (full_name or email) for customer_id 42.
    -- Since the column was dropped, we expect this count to be zero.
    ISNULL((
        SELECT COUNT(1)
        FROM dbo.customer
        WHERE customer_id = 42
          AND (
              full_name LIKE '%+1-555-0000042%' 
              OR email LIKE '%+1-555-0000042%'
          )
    ), 0) AS rows_found;
