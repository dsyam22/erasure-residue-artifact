DECLARE @customer_id int = 42;
DECLARE @full_name nvarchar(255) = N'Subject_0000042';
DECLARE @email nvarchar(255) = N'subject42@example.invalid';
DECLARE @phone nvarchar(255) = N'+1-555-0000042';

CREATE TABLE #results (
    object_name nvarchar(255),
    rows_found bigint
);

-- Check base table
INSERT INTO #results (object_name, rows_found)
SELECT N'dbo.customer', COUNT(*)
FROM dbo.customer
WHERE customer_id = @customer_id
  AND full_name = @full_name
  AND email = @email
  AND phone = @phone;

-- Check CDC change table
IF EXISTS (
    SELECT 1 FROM sys.tables t
    JOIN sys.schemas s ON t.schema_id = s.schema_id
    WHERE s.name = 'cdc' AND t.name = 'dbo_customer_CT'
)
BEGIN
    INSERT INTO #results (object_name, rows_found)
    SELECT N'cdc.dbo_customer_CT', COUNT(*)
    FROM cdc.dbo_customer_CT
    WHERE customer_id = @customer_id
      AND full_name = @full_name
      AND email = @email
      AND phone = @phone;
END
ELSE
BEGIN
    INSERT INTO #results (object_name, rows_found)
    SELECT N'cdc.dbo_customer_CT', 0;
END

-- Check temporal history table (if exists)
IF EXISTS (
    SELECT 1 FROM sys.tables t
    JOIN sys.schemas s ON t.schema_id = s.schema_id
    WHERE t.temporal_type = 1
      AND t.history_table_object_id IS NOT NULL
      AND t.object_id = OBJECT_ID('dbo.customer')
)
BEGIN
    DECLARE @history_schema nvarchar(128);
    DECLARE @history_name nvarchar(128);
    SELECT @history_schema = s.name, @history_name = h.name
    FROM sys.tables t
    JOIN sys.schemas s ON t.schema_id = s.schema_id
    JOIN sys.tables h ON t.history_table_object_id = h.object_id
    WHERE t.object_id = OBJECT_ID('dbo.customer');

    DECLARE @sql nvarchar(max);
    SET @sql = N'
        INSERT INTO #results (object_name, rows_found)
        SELECT @objname, COUNT(*)
        FROM ' + QUOTENAME(@history_schema) + N'.' + QUOTENAME(@history_name) + N'
        WHERE customer_id = @cid
          AND full_name = @fname
          AND email = @em
          AND phone = @ph;
    ';

    EXEC sp_executesql @sql,
        N'@objname nvarchar(255), @cid int, @fname nvarchar(255), @em nvarchar(255), @ph nvarchar(255)',
        @objname = @history_schema + N'.' + @history_name,
        @cid = @customer_id,
        @fname = @full_name,
        @em = @email,
        @ph = @phone;
END
ELSE
BEGIN
    -- No temporal history table for dbo.customer
    INSERT INTO #results (object_name, rows_found)
    SELECT N'dbo.customer_history', 0;
END

-- Check for any other user tables that might contain the same columns
-- This is a generic check: look for tables with columns named customer_id, full_name, email, phone
DECLARE @table_name nvarchar(255);
DECLARE @schema_name nvarchar(255);

DECLARE table_cursor CURSOR FOR
SELECT s.name, t.name
FROM sys.tables t
JOIN sys.schemas s ON t.schema_id = s.schema_id
WHERE t.object_id != OBJECT_ID('dbo.customer')
  AND EXISTS (
      SELECT 1 FROM sys.columns c
      WHERE c.object_id = t.object_id AND c.name = 'customer_id'
  )
  AND EXISTS (
      SELECT 1 FROM sys.columns c
      WHERE c.object_id = t.object_id AND c.name = 'full_name'
  )
  AND EXISTS (
      SELECT 1 FROM sys.columns c
      WHERE c.object_id = t.object_id AND c.name = 'email'
  )
  AND EXISTS (
      SELECT 1 FROM sys.columns c
      WHERE c.object_id = t.object_id AND c.name = 'phone'
  );

OPEN table_cursor;
FETCH NEXT FROM table_cursor INTO @schema_name, @table_name;

WHILE @@FETCH_STATUS = 0
BEGIN
    DECLARE @obj_name nvarchar(255) = @schema_name + N'.' + @table_name;
    DECLARE @dynamic_sql nvarchar(max) = N'
        INSERT INTO #results (object_name, rows_found)
        SELECT @objname, COUNT(*)
        FROM ' + QUOTENAME(@schema_name) + N'.' + QUOTENAME(@table_name) + N'
        WHERE customer_id = @cid
          AND full_name = @fname
          AND email = @em
          AND phone = @ph;
    ';

    EXEC sp_executesql @dynamic_sql,
        N'@objname nvarchar(255), @cid int, @fname nvarchar(255), @em nvarchar(255), @ph nvarchar(255)',
        @objname = @obj_name,
        @cid = @customer_id,
        @fname = @full_name,
        @em = @email,
        @ph = @phone;

    FETCH NEXT FROM table_cursor INTO @schema_name, @table_name;
END

CLOSE table_cursor;
DEALLOCATE table_cursor;

-- Return final result set
SELECT object_name, rows_found
FROM #results
ORDER BY object_name;

DROP TABLE #results;
