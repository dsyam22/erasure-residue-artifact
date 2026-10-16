DECLARE @customer_id int = 42;
DECLARE @member_id int = 42;
DECLARE @full_name nvarchar(200) = N'Subject_0000042';
DECLARE @email nvarchar(320) = N'subject42@example.invalid';
DECLARE @phone nvarchar(50) = N'+1-555-0000042';

CREATE TABLE #results (object_name sysname PRIMARY KEY, rows_found bigint NOT NULL);

INSERT INTO #results (object_name, rows_found) VALUES (N'dbo.customer', 0);
INSERT INTO #results (object_name, rows_found) VALUES (N'dbo.member', 0);

UPDATE #results
SET rows_found = (
    SELECT COUNT_BIG(*)
    FROM dbo.customer
    WHERE customer_id = @customer_id
       OR full_name = @full_name
       OR email = @email
       OR phone = @phone
)
WHERE object_name = N'dbo.customer';

UPDATE #results
SET rows_found = (
    SELECT COUNT_BIG(*)
    FROM dbo.member
    WHERE member_id = @member_id
       OR full_name = @full_name
       OR email = @email
       OR phone = @phone
)
WHERE object_name = N'dbo.member';

SELECT object_name, rows_found
FROM #results
ORDER BY object_name;

DROP TABLE #results;
