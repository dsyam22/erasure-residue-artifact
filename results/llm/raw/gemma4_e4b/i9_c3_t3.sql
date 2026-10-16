WITH CustomerCheck AS (
    -- Check 1: The primary table (dbo.customer) - Current records after DELETE
    SELECT
        'dbo.customer' AS object_name,
        CAST(COUNT(1) AS INT) AS rows_found
    FROM
        dbo.customer
    WHERE
        customer_id = 42
        AND full_name = 'Subject_0000042'
        AND email = 'subject42@example.invalid'
        AND phone = '+1-555-0000042'
),
HistoryCheck AS (
    -- Check 2: The system versioned history table (dbo.customer_history) - Historical records
    SELECT
        'dbo.customer_history' AS object_name,
        CAST(COUNT(1) AS INT) AS rows_found
    FROM
        dbo.customer_history
    WHERE
        customer_id = 42
        AND full_name = 'Subject_0000042'
        AND email = 'subject42@example.invalid'
        AND phone = '+1-555-0000042'
)
-- Combine the results into a single required result set
SELECT * FROM CustomerCheck
UNION ALL
SELECT * FROM HistoryCheck;
