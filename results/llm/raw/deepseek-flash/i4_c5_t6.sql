-- SCRIPT
DECLARE @subject_customer_id int = 42;
DECLARE @subject_member_id int = 42;
DECLARE @subject_full_name nvarchar(200) = N'Subject_0000042';
DECLARE @subject_email nvarchar(320) = N'subject42@example.invalid';
DECLARE @subject_phone nvarchar(50) = N'+1-555-0000042';

SELECT object_name, rows_found
FROM (
    SELECT
        'dbo.customer' AS object_name,
        (
            SELECT COUNT(*)
            FROM dbo.customer
            WHERE customer_id = @subject_customer_id
              AND (
                    full_name = @subject_full_name
                 OR email = @subject_email
                 OR phone = @subject_phone
              )
        ) AS rows_found

    UNION ALL

    SELECT
        'dbo.member' AS object_name,
        (
            SELECT COUNT(*)
            FROM dbo.member
            WHERE member_id = @subject_member_id
              AND (
                    full_name = @subject_full_name
                 OR email = @subject_email
                 OR phone = @subject_phone
              )
        ) AS rows_found
) AS checks;
