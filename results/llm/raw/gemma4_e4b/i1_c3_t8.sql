DECLARE @target_customer_id INT = 42;
DECLARE @target_full_name NVARCHAR(100) = 'Subject_0000042';
DECLARE @target_email NVARCHAR(150) = 'subject42@example.invalid';
DECLARE @target_phone NVARCHAR(50) = '+1-555-0000042';

SELECT object_name, rows_found FROM (
    -- 1. Check the primary current table state (dbo.customer)
    SELECT
        'dbo.customer' AS object_name,
        CAST(COUNT(1) AS INT) AS rows_found
    FROM
        dbo.customer
    WHERE
        customer_id = @target_customer_id
        AND full_name = @target_full_name
        AND email = @target_email
        AND phone = @target_phone

    UNION ALL

    -- 2. Check the CDC Change Table (cdc.dbo_customer_CT) for deleted records
    SELECT
        'cdc.dbo_customer_CT' AS object_name,
        CAST(COUNT(1) AS INT) AS rows_found
    FROM
        cdc.dbo_customer_CT
    WHERE
        -- Matching on all attributes ensures we found the specific record that was deleted
        customer_id = @target_customer_id
        AND full_name = @target_full_name
        AND email = @target_email
        AND phone = @target_phone

) AS results;
