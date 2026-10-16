WITH Customer_Check AS (
    SELECT 'dbo.customer' AS object_name, 
           CAST(COUNT(CASE WHEN full_name = 'Subject_0000042' OR email = 'subject42@example.invalid' OR phone = '+1-555-0000042' THEN 1 END) AS BIGINT) AS rows_found
    FROM dbo.customer
),
Customer_CDC_Check AS (
    SELECT 'cdc.dbo_customer_CT' AS object_name, 
           CAST(COUNT(CASE WHEN full_name = 'Subject_0000042' OR email = 'subject42@example.invalid' OR phone = '+1-555-0000042' THEN 1 END) AS BIGINT) AS rows_found
    FROM cdc.dbo_customer_CT
),
Member_Current_Check AS (
    SELECT 'dbo.member' AS object_name, 
           CAST(COUNT(CASE WHEN full_name = 'Subject_0000042' OR email = 'subject42@example.invalid' OR phone = '+1-555-0000042' THEN 1 END) AS BIGINT) AS rows_found
    FROM dbo.member
),
Member_History_Check AS (
    SELECT 'dbo.member_history' AS object_name, 
           CAST(COUNT(CASE WHEN full_name = 'Subject_0000042' OR email = 'subject42@example.invalid' OR phone = '+1-555-0000042' THEN 1 END) AS BIGINT) AS rows_found
    FROM dbo.member_history
)
SELECT object_name, rows_found FROM Customer_Check
UNION ALL
SELECT object_name, rows_found FROM Customer_CDC_Check
UNION ALL
SELECT object_name, rows_found FROM Member_Current_Check
UNION ALL
SELECT object_name, rows_found FROM Member_History_Check;
