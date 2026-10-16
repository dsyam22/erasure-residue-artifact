-- SCRIPT
DECLARE @customer_id int = 42;
DECLARE @full_name nvarchar(200) = N'Subject_0000042';
DECLARE @email nvarchar(320) = N'subject42@example.invalid';
DECLARE @phone nvarchar(50) = N'+1-555-0000042';

;WITH checked_objects AS (
    SELECT N'dbo.customer' AS object_name, 1 AS ord
    UNION ALL
    SELECT N'dbo.member', 2
),
customer_hits AS (
    SELECT COUNT_BIG(*) AS rows_found
    FROM dbo.customer
    WHERE customer_id = @customer_id
      AND (
            full_name = @full_name
         OR email = @email
         OR phone = @phone
      )
),
member_hits AS (
    SELECT COUNT_BIG(*) AS rows_found
    FROM dbo.member
    WHERE member_id = @customer_id
      AND (
            full_name = @full_name
         OR email = @email
         OR phone = @phone
      )
)
SELECT
    c.object_name,
    CASE c.object_name
        WHEN N'dbo.customer' THEN (SELECT rows_found FROM customer_hits)
        WHEN N'dbo.member' THEN (SELECT rows_found FROM member_hits)
    END AS rows_found
FROM checked_objects AS c
ORDER BY c.ord;
