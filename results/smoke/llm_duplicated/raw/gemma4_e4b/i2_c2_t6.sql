WITH CustomerCheck AS (
    -- Check the main, currently active table
    SELECT
        'dbo.customer' AS object_name,
        CAST(ISNULL((
            SELECT COUNT(*)
            FROM dbo.customer
            WHERE full_name = 'Subject_0000042' 
               OR email = 'subject42@example.invalid' 
               OR phone = '+1-555-0000042'
        ), 0) AS bigint) AS rows_found
),
HistoryCheck AS (
    -- Check the history table where deleted data resides
    SELECT
        'dbo.customer_history' AS object_name,
        CAST(ISNULL((
            SELECT COUNT(*)
            FROM dbo.customer_history
            WHERE full_name = 'Subject_0000042' 
               OR email = 'subject42@example.invalid' 
               OR phone = '+1-555-0000042'
        ), 0) AS bigint) AS rows_found
)
SELECT object_name, rows_found FROM CustomerCheck
UNION ALL
SELECT object_name, rows_found FROM HistoryCheck;
