SET NOCOUNT ON;

DECLARE @cid   int            = 42,
        @name  nvarchar(200)  = N'Subject_0000042',
        @email nvarchar(400)  = N'subject42@example.invalid',
        @phone nvarchar(60)   = N'+1-555-0000042';

SELECT x.object_name, x.rows_found
FROM (
    SELECT N'dbo.customer' AS object_name,
           COUNT(*)        AS rows_found
    FROM dbo.customer
    WHERE customer_id = @cid
       OR full_name   = @name
       OR email       = @email
       OR phone       = @phone

    UNION ALL

    SELECT N'dbo.customer_history',
           COUNT(*)
    FROM dbo.customer_history
    WHERE customer_id = @cid
       OR full_name   = @name
       OR email       = @email
       OR phone       = @phone
) AS x
ORDER BY x.object_name;
