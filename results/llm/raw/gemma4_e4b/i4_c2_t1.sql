WITH CheckCustomer AS (
    SELECT 'dbo.customer' AS object_name,
           CAST(COUNT(*) AS INT) AS rows_found
    FROM dbo.customer
    WHERE full_name = 'Subject_0000042' OR email = 'subject42@example.invalid' OR phone = '+1-555-0000042'
),
CheckMember AS (
    SELECT 'dbo.member' AS object_name,
           CAST(COUNT(*) AS INT) AS rows_found
    FROM dbo.member
    WHERE full_name = 'Subject_0000042' OR email = 'subject42@example.invalid' OR phone = '+1-555-0000042'
),
CheckMemberHistory AS (
    SELECT 'dbo.member_history' AS object_name,
           CAST(COUNT(*) AS INT) AS rows_found
    FROM dbo.member_history
    WHERE full_name = 'Subject_0000042' OR email = 'subject42@example.invalid' OR phone = '+1-555-0000042'
),
CheckCDCCustomer AS (
    SELECT 'cdc.dbo_customer_CT' AS object_name,
           CAST(COUNT(*) AS INT) AS rows_found
    FROM cdc.dbo_customer_CT
    WHERE full_name = 'Subject_0000042' OR email = 'subject42@example.invalid' OR phone = '+1-555-0000042'
)
SELECT object_name, rows_found FROM CheckCustomer
UNION ALL
SELECT object_name, rows_found FROM CheckMember
UNION ALL
SELECT object_name, rows_found FROM CheckMemberHistory
UNION ALL
SELECT object_name, rows_found FROM CheckCDCCustomer;
