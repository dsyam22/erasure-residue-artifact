SET NOCOUNT ON;

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

-- Check temporal history table
INSERT INTO #results (object_name, rows_found)
SELECT N'dbo.customer_history', COUNT(*)
FROM dbo.customer_history
WHERE customer_id = @customer_id
   OR full_name = @full_name
   OR email = @email
   OR phone = @phone;

-- Check for CDC-enabled tables (if any)
IF EXISTS (SELECT 1 FROM sys.tables t
           INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
           WHERE t.is_tracked_by_cdc = 1
             AND s.name = N'dbo' AND t.name = N'customer')
BEGIN
    INSERT INTO #results (object_name, rows_found)
    SELECT N'cdc.dbo_customer_CT', COUNT(*)
    FROM cdc.dbo_customer_CT
    WHERE customer_id = @customer_id
       OR full_name = @full_name
       OR email = @email
       OR phone = @phone;
END
ELSE
BEGIN
    INSERT INTO #results (object_name, rows_found)
    SELECT N'cdc.dbo_customer_CT', 0;
END

-- Check for any other tables that might contain the data (heuristic: same column names)
DECLARE @sql nvarchar(max) = N'';
DECLARE @table_name nvarchar(255);
DECLARE @schema_name nvarchar(255);

DECLARE table_cursor CURSOR FOR
SELECT s.name, t.name
FROM sys.tables t
INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
WHERE t.name <> N'customer'
  AND EXISTS (
      SELECT 1 FROM sys.columns c
      WHERE c.object_id = t.object_id
        AND c.name IN (N'customer_id', N'full_name', N'email', N'phone')
  );

OPEN table_cursor;
FETCH NEXT FROM table_cursor INTO @schema_name, @table_name;

WHILE @@FETCH_STATUS = 0
BEGIN
    DECLARE @qualified_name nvarchar(255) = QUOTENAME(@schema_name) + N'.' + QUOTENAME(@table_name);
    DECLARE @dynamic_sql nvarchar(max) = N'SELECT @cnt = COUNT(*) FROM ' + @qualified_name + N' WHERE ';
    DECLARE @conditions nvarchar(max) = N'';
    DECLARE @cnt int = 0;

    IF EXISTS (SELECT 1 FROM sys.columns c WHERE c.object_id = OBJECT_ID(@qualified_name) AND c.name = N'customer_id')
        SET @conditions = @conditions + N'customer_id = @customer_id OR ';
    IF EXISTS (SELECT 1 FROM sys.columns c WHERE c.object_id = OBJECT_ID(@qualified_name) AND c.name = N'full_name')
        SET @conditions = @conditions + N'full_name = @full_name OR ';
    IF EXISTS (SELECT 1 FROM sys.columns c WHERE c.object_id = OBJECT_ID(@qualified_name) AND c.name = N'email')
        SET @conditions = @conditions + N'email = @email OR ';
    IF EXISTS (SELECT 1 FROM sys.columns c WHERE c.object_id = OBJECT_ID(@qualified_name) AND c.name = N'phone')
        SET @conditions = @conditions + N'phone = @phone OR ';

    IF LEN(@conditions) > 0
    BEGIN
        SET @conditions = LEFT(@conditions, LEN(@conditions) - 3); -- remove trailing ' OR '
        SET @dynamic_sql = @dynamic_sql + @conditions;
        EXEC sp_executesql @dynamic_sql, N'@customer_id int, @full_name nvarchar(255), @email nvarchar(255), @phone nvarchar(255), @cnt int OUTPUT',
                           @customer_id, @full_name, @email, @phone, @cnt OUTPUT;
        INSERT INTO #results (object_name, rows_found)
        SELECT @qualified_name, @cnt;
    END

    FETCH NEXT FROM table_cursor INTO @schema_name, @table_name;
END

CLOSE table_cursor;
DEALLOCATE table_cursor;

-- Return results
SELECT object_name, rows_found
FROM #results
ORDER BY object_name;

DROP TABLE #results;
