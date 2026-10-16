SET NOCOUNT ON;

DECLARE @customer_id INT = 42;
DECLARE @full_name NVARCHAR(255) = N'Subject_0000042';
DECLARE @email NVARCHAR(255) = N'subject42@example.invalid';
DECLARE @phone NVARCHAR(255) = N'+1-555-0000042';

CREATE TABLE #Results (
    object_name NVARCHAR(255) NOT NULL,
    rows_found INT NOT NULL
);

-- Check current table
INSERT INTO #Results (object_name, rows_found)
SELECT N'dbo.customer', COUNT(*)
FROM dbo.customer
WHERE customer_id = @customer_id
   OR full_name = @full_name
   OR email = @email
   OR phone = @phone;

-- Check temporal history table
INSERT INTO #Results (object_name, rows_found)
SELECT N'dbo.customer_history', COUNT(*)
FROM dbo.customer_history
WHERE customer_id = @customer_id
   OR full_name = @full_name
   OR email = @email
   OR phone = @phone;

-- Check CDC change tables (if any exist for this table)
IF EXISTS (
    SELECT 1
    FROM sys.tables t
    JOIN sys.schemas s ON t.schema_id = s.schema_id
    WHERE t.name = N'customer'
      AND t.is_tracked_by_cdc = 1
)
BEGIN
    DECLARE @cdc_schema NVARCHAR(255);
    DECLARE @cdc_table NVARCHAR(255);
    DECLARE @sql NVARCHAR(MAX);

    SELECT @cdc_schema = s.name, @cdc_table = t.name
    FROM sys.tables t
    JOIN sys.schemas s ON t.schema_id = s.schema_id
    WHERE t.name = N'customer'
      AND t.is_tracked_by_cdc = 1;

    SET @cdc_schema = QUOTENAME(@cdc_schema);
    SET @cdc_table = QUOTENAME(@cdc_table);

    SET @sql = N'
        INSERT INTO #Results (object_name, rows_found)
        SELECT N''' + @cdc_schema + N'.' + @cdc_table + N''', COUNT(*)
        FROM ' + @cdc_schema + N'.' + @cdc_table + N'
        WHERE customer_id = @customer_id
           OR full_name = @full_name
           OR email = @email
           OR phone = @phone;';

    EXEC sp_executesql @sql,
        N'@customer_id INT, @full_name NVARCHAR(255), @email NVARCHAR(255), @phone NVARCHAR(255)',
        @customer_id, @full_name, @email, @phone;
END
ELSE
BEGIN
    INSERT INTO #Results (object_name, rows_found)
    SELECT N'cdc.dbo_customer_CT', 0;
END

-- Return final result set
SELECT object_name, rows_found
FROM #Results
ORDER BY object_name;

DROP TABLE #Results;
