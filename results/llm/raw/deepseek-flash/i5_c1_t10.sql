SELECT object_name, rows_found
FROM (
    SELECT 'dbo.customer' AS object_name,
           (SELECT COUNT(*)
            FROM dbo.customer
            WHERE customer_id = 42
               OR full_name = N'Subject_0000042'
               OR email = N'subject42@example.invalid'
               OR phone = N'+1-555-0000042') AS rows_found
    UNION ALL
    SELECT 'dbo.customer_history' AS object_name,
           CASE WHEN OBJECT_ID('dbo.customer_history') IS NULL THEN 0
                ELSE (SELECT COUNT(*)
                      FROM dbo.customer_history
                      WHERE customer_id = 42
                         OR full_name = N'Subject_0000042'
                         OR email = N'subject42@example.invalid'
                         OR phone = N'+1-555-0000042')
           END AS rows_found
    UNION ALL
    SELECT 'dbo.audit_log' AS object_name,
           CASE WHEN OBJECT_ID('dbo.audit_log') IS NULL THEN 0
                ELSE (SELECT COUNT(*)
                      FROM dbo.audit_log
                      WHERE CAST(details AS nvarchar(max)) LIKE N'%Subject_0000042%'
                         OR CAST(details AS nvarchar(max)) LIKE N'%subject42@example.invalid%'
                         OR CAST(details AS nvarchar(max)) LIKE N'%+1-555-0000042%')
           END AS rows_found
    UNION ALL
    SELECT 'dbo.orders' AS object_name,
           CASE WHEN OBJECT_ID('dbo.orders') IS NULL THEN 0
                ELSE (SELECT COUNT(*)
                      FROM dbo.orders
                      WHERE customer_id = 42)
           END AS rows_found
    UNION ALL
    SELECT 'dbo.payments' AS object_name,
           CASE WHEN OBJECT_ID('dbo.payments') IS NULL THEN 0
                ELSE (SELECT COUNT(*)
                      FROM dbo.payments
                      WHERE customer_id = 42)
           END AS rows_found
    UNION ALL
    SELECT 'dbo.addresses' AS object_name,
           CASE WHEN OBJECT_ID('dbo.addresses') IS NULL THEN 0
                ELSE (SELECT COUNT(*)
                      FROM dbo.addresses
                      WHERE customer_id = 42
                         OR full_name = N'Subject_0000042'
                         OR email = N'subject42@example.invalid'
                         OR phone = N'+1-555-0000042')
           END AS rows_found
    UNION ALL
    SELECT 'dbo.contacts' AS object_name,
           CASE WHEN OBJECT_ID('dbo.contacts') IS NULL THEN 0
                ELSE (SELECT COUNT(*)
                      FROM dbo.contacts
                      WHERE customer_id = 42
                         OR email = N'subject42@example.invalid'
                         OR phone = N'+1-555-0000042')
           END AS rows_found
) AS checks
ORDER BY object_name;
