DECLARE @needle nvarchar(4000) = N'+1-555-0000042';

CREATE TABLE #results (object_name sysname, rows_found bigint);

INSERT INTO #results (object_name, rows_found)
SELECT N'dbo.customer', COUNT(*)
FROM dbo.customer
WHERE (full_name LIKE N'%' + @needle + N'%')
   OR (email     LIKE N'%' + @needle + N'%');

INSERT INTO #results (object_name, rows_found)
SELECT N'dbo.customer.full_name', COUNT(*)
FROM dbo.customer
WHERE full_name LIKE N'%' + @needle + N'%';

INSERT INTO #results (object_name, rows_found)
SELECT N'dbo.customer.email', COUNT(*)
FROM dbo.customer
WHERE email LIKE N'%' + @needle + N'%';

SELECT object_name, rows_found
FROM #results;

DROP TABLE #results;
