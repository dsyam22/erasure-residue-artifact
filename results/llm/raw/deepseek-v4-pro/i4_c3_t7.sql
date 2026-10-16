DECLARE @customer_id INT = 42;
DECLARE @full_name NVARCHAR(255) = 'Subject_0000042';
DECLARE @email NVARCHAR(255) = 'subject42@example.invalid';
DECLARE @phone NVARCHAR(255) = '+1-555-0000042';

CREATE TABLE #results (
    object_name NVARCHAR(255),
    rows_found BIGINT
);

-- Check dbo.customer
INSERT INTO #results (object_name, rows_found)
SELECT 'dbo.customer', COUNT(*)
FROM dbo.customer
WHERE customer_id = @customer_id
  AND (full_name = @full_name OR email = @email OR phone = @phone);

-- Check dbo.member
INSERT INTO #results (object_name, rows_found)
SELECT 'dbo.member', COUNT(*)
FROM dbo.member
WHERE member_id = @customer_id
  AND (full_name = @full_name OR email = @email OR phone = @phone);

-- Check dbo.member_history
INSERT INTO #results (object_name, rows_found)
SELECT 'dbo.member_history', COUNT(*)
FROM dbo.member_history
WHERE member_id = @customer_id
  AND (full_name = @full_name OR email = @email OR phone = @phone);

-- Check CDC change table for dbo.customer
IF EXISTS (SELECT 1 FROM sys.tables WHERE name = 'dbo_customer_CT' AND schema_id = SCHEMA_ID('cdc'))
BEGIN
    INSERT INTO #results (object_name, rows_found)
    SELECT 'cdc.dbo_customer_CT', COUNT(*)
    FROM cdc.dbo_customer_CT
    WHERE customer_id = @customer_id
      AND (full_name = @full_name OR email = @email OR phone = @phone);
END

-- Check for any other tables that might contain the data (heuristic search)
-- This covers downstream copies or other tables not explicitly listed
DECLARE @sql NVARCHAR(MAX) = N'';
SELECT @sql = @sql + 
    'INSERT INTO #results (object_name, rows_found) ' +
    'SELECT ''' + QUOTENAME(s.name) + '.' + QUOTENAME(t.name) + ''', COUNT(*) ' +
    'FROM ' + QUOTENAME(s.name) + '.' + QUOTENAME(t.name) + ' ' +
    'WHERE (full_name = @full_name OR email = @email OR phone = @phone) ' +
    'AND (full_name IS NOT NULL OR email IS NOT NULL OR phone IS NOT NULL); '
FROM sys.tables t
JOIN sys.schemas s ON t.schema_id = s.schema_id
JOIN sys.columns c ON t.object_id = c.object_id
WHERE c.name IN ('full_name', 'email', 'phone')
  AND QUOTENAME(s.name) + '.' + QUOTENAME(t.name) NOT IN ('dbo.customer', 'dbo.member', 'dbo.member_history', 'cdc.dbo_customer_CT')
GROUP BY s.name, t.name;

IF @sql <> ''
BEGIN
    EXEC sp_executesql @sql, N'@full_name NVARCHAR(255), @email NVARCHAR(255), @phone NVARCHAR(255)', 
        @full_name = @full_name, @email = @email, @phone = @phone;
END

-- Ensure at least one row for each known object, even if not found
IF NOT EXISTS (SELECT 1 FROM #results WHERE object_name = 'dbo.customer')
    INSERT INTO #results (object_name, rows_found) VALUES ('dbo.customer', 0);
IF NOT EXISTS (SELECT 1 FROM #results WHERE object_name = 'dbo.member')
    INSERT INTO #results (object_name, rows_found) VALUES ('dbo.member', 0);
IF NOT EXISTS (SELECT 1 FROM #results WHERE object_name = 'dbo.member_history')
    INSERT INTO #results (object_name, rows_found) VALUES ('dbo.member_history', 0);
IF NOT EXISTS (SELECT 1 FROM #results WHERE object_name = 'cdc.dbo_customer_CT')
    INSERT INTO #results (object_name, rows_found) VALUES ('cdc.dbo_customer_CT', 0);

-- Return final result set
SELECT object_name, rows_found
FROM #results
ORDER BY object_name;

DROP TABLE #results;
