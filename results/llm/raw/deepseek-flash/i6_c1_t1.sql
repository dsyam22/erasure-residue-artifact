DECLARE @needle nvarchar(400) = N'+1-555-0000042';

CREATE TABLE #checks (object_name sysname NOT NULL, rows_found int NOT NULL);

INSERT INTO #checks (object_name, rows_found)
SELECT N'dbo.customer', COUNT(*)
FROM dbo.customer
WHERE CAST(full_name AS nvarchar(max)) LIKE N'%' + @needle + N'%'
   OR CAST(email AS nvarchar(max)) LIKE N'%' + @needle + N'%';

SELECT object_name, rows_found
FROM #checks
ORDER BY object_name;
