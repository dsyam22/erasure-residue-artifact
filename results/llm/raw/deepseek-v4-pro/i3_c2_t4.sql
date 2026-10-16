SET NOCOUNT ON;

DECLARE @customer_id int = 42;
DECLARE @full_name nvarchar(255) = N'Subject_0000042';
DECLARE @email nvarchar(255) = N'subject42@example.invalid';
DECLARE @phone nvarchar(255) = N'+1-555-0000042';

CREATE TABLE #results (
    object_name nvarchar(255) NOT NULL,
    rows_found int NOT NULL
);

-- Check dbo.customer (current table)
INSERT INTO #results (object_name, rows_found)
SELECT N'dbo.customer', COUNT(*)
FROM dbo.customer
WHERE customer_id = @customer_id
   OR full_name = @full_name
   OR email = @email
   OR phone = @phone;

-- Check dbo.member (current system-versioned table)
INSERT INTO #results (object_name, rows_found)
SELECT N'dbo.member', COUNT(*)
FROM dbo.member
WHERE member_id = @customer_id
   OR full_name = @full_name
   OR email = @email
   OR phone = @phone;

-- Check dbo.member_history (history table)
INSERT INTO #results (object_name, rows_found)
SELECT N'dbo.member_history', COUNT(*)
FROM dbo.member_history
WHERE member_id = @customer_id
   OR full_name = @full_name
   OR email = @email
   OR phone = @phone;

-- Check CDC capture instance for dbo.customer
IF EXISTS (SELECT 1 FROM sys.tables t
           INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
           WHERE s.name = N'cdc' AND t.name = N'dbo_customer_CT')
BEGIN
    DECLARE @sql nvarchar(max) = N'
        INSERT INTO #results (object_name, rows_found)
        SELECT N''cdc.dbo_customer_CT'', COUNT(*)
        FROM cdc.dbo_customer_CT
        WHERE customer_id = @customer_id
           OR full_name = @full_name
           OR email = @email
           OR phone = @phone;';
    EXEC sp_executesql @sql, N'@customer_id int, @full_name nvarchar(255), @email nvarchar(255), @phone nvarchar(255)',
                       @customer_id, @full_name, @email, @phone;
END
ELSE
BEGIN
    INSERT INTO #results (object_name, rows_found)
    SELECT N'cdc.dbo_customer_CT', 0;
END

-- Check dbo.customer for any other system-versioned or temporal artifacts
-- (Already covered above; no additional temporal tables in schema)

-- Return final result set
SELECT object_name, rows_found
FROM #results
ORDER BY object_name;

DROP TABLE #results;
