DECLARE @customer_id int = 42;
DECLARE @full_name nvarchar(255) = N'Subject_0000042';
DECLARE @email nvarchar(255) = N'subject42@example.invalid';
DECLARE @phone nvarchar(255) = N'+1-555-0000042';

CREATE TABLE #results (
    object_name nvarchar(255) NOT NULL,
    rows_found int NOT NULL
);

-- Check base table
INSERT INTO #results (object_name, rows_found)
SELECT N'dbo.customer', COUNT(*)
FROM dbo.customer
WHERE customer_id = @customer_id
   OR full_name = @full_name
   OR email = @email
   OR phone = @phone;

-- Check CDC change table
INSERT INTO #results (object_name, rows_found)
SELECT N'cdc.dbo_customer_CT', COUNT(*)
FROM cdc.dbo_customer_CT
WHERE customer_id = @customer_id
   OR full_name = @full_name
   OR email = @email
   OR phone = @phone;

-- Check any temporal history table if exists (not indicated, but include for completeness)
IF EXISTS (
    SELECT 1 FROM sys.tables t
    JOIN sys.schemas s ON t.schema_id = s.schema_id
    WHERE t.name = 'customer' AND t.temporal_type = 2
)
BEGIN
    DECLARE @history_schema nvarchar(128);
    DECLARE @history_table nvarchar(128);
    
    SELECT @history_schema = s.name, @history_table = t.history_table_name
    FROM sys.tables t
    JOIN sys.schemas s ON t.schema_id = s.schema_id
    WHERE t.name = 'customer' AND t.temporal_type = 2;
    
    DECLARE @sql nvarchar(max) = N'SELECT @cnt = COUNT(*) FROM ' + QUOTENAME(@history_schema) + N'.' + QUOTENAME(@history_table) + 
        N' WHERE customer_id = @cid OR full_name = @fn OR email = @em OR phone = @ph';
    DECLARE @cnt int;
    EXEC sp_executesql @sql, N'@cid int, @fn nvarchar(255), @em nvarchar(255), @ph nvarchar(255), @cnt int OUTPUT',
        @cid = @customer_id, @fn = @full_name, @em = @email, @ph = @phone, @cnt = @cnt OUTPUT;
    
    INSERT INTO #results (object_name, rows_found)
    SELECT QUOTENAME(@history_schema) + N'.' + QUOTENAME(@history_table), @cnt;
END
ELSE
BEGIN
    INSERT INTO #results (object_name, rows_found)
    SELECT N'dbo.customer_history', 0
    WHERE 1 = 0; -- placeholder, no actual history table
END

SELECT object_name, rows_found
FROM #results
ORDER BY object_name;

DROP TABLE #results;
