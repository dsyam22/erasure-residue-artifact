DECLARE @subject_customer_id int = 42;
DECLARE @subject_full_name nvarchar(200) = N'Subject_0000042';
DECLARE @subject_email nvarchar(320) = N'subject42@example.invalid';
DECLARE @subject_phone nvarchar(64) = N'+1-555-0000042';

SELECT
    CAST(N'dbo.customer' AS nvarchar(256)) AS object_name,
    (SELECT COUNT(*)
     FROM dbo.customer AS c
     WHERE c.customer_id = @subject_customer_id
        OR c.full_name = @subject_full_name
        OR c.email = @subject_email
        OR c.phone = @subject_phone) AS rows_found
UNION ALL
SELECT
    CAST(N'cdc.dbo_customer_CT' AS nvarchar(256)),
    (SELECT COUNT(*)
     FROM cdc.dbo_customer_CT AS ct
     WHERE ct.customer_id = @subject_customer_id
        OR ct.full_name = @subject_full_name
        OR ct.email = @subject_email
        OR ct.phone = @subject_phone);
