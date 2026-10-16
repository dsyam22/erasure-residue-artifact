DECLARE @Name NVARCHAR(100) = 'Subject_0000042';
DECLARE @Email NVARCHAR(100) = 'subject42@example.invalid';
DECLARE @Phone NVARCHAR(50) = '+1-555-0000042';

SELECT 'dbo.customer' AS object_name, CAST(COUNT(CASE WHEN T.full_name = @Name OR T.email = @Email OR T.phone = @Phone THEN 1 END) AS INT) AS rows_found
FROM dbo.customer AS T
WHERE T.customer_id = 42

UNION ALL

SELECT 'cdc.dbo_customer_CT' AS object_name, CAST(COUNT(CASE WHEN T.full_name = @Name OR T.email = @Email OR T.phone = @Phone THEN 1 END) AS INT) AS rows_found
FROM cdc.dbo_customer_CT AS T
WHERE T.customer_id = 42

UNION ALL

SELECT 'dbo.member' AS object_name, CAST(COUNT(CASE WHEN T.full_name = @Name OR T.email = @Email OR T.phone = @Phone THEN 1 END) AS INT) AS rows_found
FROM dbo.member AS T
WHERE T.member_id = 42

UNION ALL

SELECT 'dbo.member_history' AS object_name, CAST(COUNT(CASE WHEN T.full_name = @Name OR T.email = @Email OR T.phone = @Phone THEN 1 END) AS INT) AS rows_found
FROM dbo.member_history AS T
WHERE T.member_id = 42;
