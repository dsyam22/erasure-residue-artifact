-- SCRIPT
SET NOCOUNT ON;

DECLARE @subject_customer_id int = 42;
DECLARE @subject_full_name nvarchar(200) = N'Subject_0000042';
DECLARE @subject_email nvarchar(320) = N'subject42@example.invalid';
DECLARE @subject_phone nvarchar(50) = N'+1-555-0000042';

SELECT
    object_name,
    rows_found
FROM (
    SELECT
        N'dbo.customer' AS object_name,
        COUNT(*) AS rows_found
    FROM dbo.customer
    WHERE customer_id = @subject_customer_id
       OR full_name = @subject_full_name
       OR email = @subject_email
       OR phone = @subject_phone
) AS results;
