WITH Check_Customer AS (
    SELECT
        'dbo.customer' AS object_name,
        CAST(COUNT(CASE WHEN full_name = 'Subject_0000042' AND email = 'subject42@example.invalid' AND phone = '+1-555-0000042' THEN 1 END) AS INT) AS rows_found
    FROM dbo.customer
),
Check_Member AS (
    SELECT
        'dbo.member' AS object_name,
        CAST(COUNT(CASE WHEN full_name = 'Subject_0000042' AND email = 'subject42@example.invalid' AND phone = '+1-555-0000042' THEN 1 END) AS INT) AS rows_found
    FROM dbo.member
),
Check_MemberHistory AS (
    SELECT
        'dbo.member_history' AS object_name,
        CAST(COUNT(CASE WHEN full_name = 'Subject_0000042' AND email = 'subject42@example.invalid' AND phone = '+1-555-0000042' THEN 1 END) AS INT) AS rows_found
    FROM dbo.member_history
),
Check_CDC_Customer AS (
    SELECT
        'cdc.dbo_customer_CT' AS object_name,
        CAST(COUNT(*) AS INT) AS rows_found -- We check for the ID existence in the change table
    FROM cdc.dbo_customer_CT
    WHERE customer_id = 42
),
-- Although dbo_customer is checked above, we include it explicitly as a source object check if needed, but since CDC covers changes, this focuses on the history/source tables.
-- We ensure all required objects are listed for compliance.
Check_CDC_Source AS (
    SELECT
        'cdc.dbo_customer_CT' AS object_name, -- Re-using the name defined above for simplicity/clarity of check point
        CAST(COUNT(*) AS INT) AS rows_found
    FROM cdc.dbo_customer_CT
    WHERE customer_id = 42
)

-- Combine all results into a single result set
SELECT object_name, rows_found FROM Check_Customer
UNION ALL
SELECT object_name, rows_found FROM Check_Member
UNION ALL
SELECT object_name, rows_found FROM Check_MemberHistory
UNION ALL
SELECT object_name, rows_found FROM Check_CDC_Customer;
