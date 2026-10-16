-- SCRIPT
SET NOCOUNT ON;

DECLARE @full_name nvarchar(200) = N'Subject_0000042';
DECLARE @email     nvarchar(200) = N'subject42@example.invalid';
DECLARE @phone     nvarchar(200) = N'+1-555-0000042';

;WITH checked AS
(
    SELECT
        object_name = N'dbo.customer',
        rows_found  = (
            SELECT COUNT(*)
            FROM dbo.customer
            WHERE customer_id = 42
              AND (
                    full_name = @full_name
                 OR email     = @email
                 OR phone     = @phone
              )
        )
    UNION ALL
    SELECT
        object_name = N'dbo.member',
        rows_found  = (
            SELECT COUNT(*)
            FROM dbo.member
            WHERE member_id = 42
              AND (
                    full_name = @full_name
                 OR email     = @email
                 OR phone     = @phone
              )
        )
)
SELECT object_name, rows_found
FROM checked;
