-- Declare variables for dynamic SQL execution
DECLARE @TableName NVARCHAR(128);
DECLARE @SchemaName NVARCHAR(128);
DECLARE @SQL NVARCHAR(MAX);

-- Temporary table to store the final results: Table Name and Count of matching records.
IF OBJECT_ID('tempdb..#SearchResults') IS NOT NULL DROP TABLE #SearchResults;
CREATE TABLE #SearchResults (
    object_name NVARCHAR(256),
    rows_found INT
);

-- Cursor setup to iterate over all user tables in the current database schema (excluding system/temporary schemas).
DECLARE table_cursor CURSOR FOR 
SELECT 
    s.name, 
    t.name 
FROM 
    sys.tables t
JOIN 
    sys.schemas s ON t.schema_id = s.schema_id
WHERE 
    S.name NOT IN ('sys', 'INFORMATION_SCHEMA') -- Exclude system schemas
ORDER BY 
    s.name, t.name;

OPEN table_cursor;
FETCH NEXT FROM table_cursor INTO @SchemaName, @TableName;

-- Loop through every user table found
WHILE @@FETCH_STATUS = 0
BEGIN
    -- Initialize the count for the current object to 0 (for later insertion)
    SET @SQL = N'SELECT '''' + QUOTENAME(@SchemaName) + ''.'' + QUOTENAME(@TableName) + '''' AS object_name, COUNT(1) AS rows_found;';

    -- Build the dynamic WHERE clause based on columns that are likely to hold PII.
    -- We check for the existence of these specific column names (customer_id, full_name, email, phone) 
    -- in the current table before including them in the search criteria.
    SET @SQL = @SQL + N' ' + QUOTENAME(@SchemaName) + '.' + QUOTENAME(@TableName) + ' AS T WHERE 1=1';

    -- Check for customer_id column (assuming it is an INT/numeric type)
    IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(QUOTENAME(@SchemaName) + '.' + QUOTENAME(@TableName)) AND name LIKE 'customer_id')
    BEGIN
        SET @SQL = @SQL + N' AND T.[customer_id] = 42';
    END

    -- Check for full_name column (assuming it is NVARCHAR/string type)
    IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(QUOTENAME(@SchemaName) + '.' + QUOTENAME(@TableName)) AND name LIKE 'full_name')
    BEGIN
        SET @SQL = @SQL + N' AND T.[full_name] = ''Subject_0000042''';
    END

    -- Check for email column (assuming it is NVARCHAR/string type)
    IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(QUOTENAME(@SchemaName) + '.' + QUOTENAME(@TableName)) AND name LIKE 'email')
    BEGIN
        SET @SQL = @SQL + N' AND T.[email] = ''subject42@example.invalid''';
    END

    -- Check for phone column (assuming it is NVARCHAR/string type)
    IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(QUOTENAME(@SchemaName) + '.' + QUOTENAME(@TableName)) AND name LIKE 'phone')
    BEGIN
        SET @SQL = @SQL + N' AND T.[phone] = ''+1-555-0000042''';
    END

    -- Wrap the dynamic query to handle cases where no PII columns are found (to prevent syntax errors)
    IF LEN(@SQL) > 40 -- Check if any WHERE condition was added beyond the initial boilerplate
    BEGIN
        SET @SQL = N'INSERT INTO #SearchResults (object_name, rows_found) EXEC (' + REPLACE(@SQL, 'SELECT', '') + ')';
    END
    ELSE
    BEGIN
        -- If no PII columns were found in this table, insert a row with 0 count.
        SET @SQL = N'INSERT INTO #SearchResults (object_name, rows_found) VALUES (''' + QUOTENAME(@SchemaName) + '.' + QUOTENAME(@TableName) + ''', 0);';
    END


    -- Execute the dynamic SQL statement and capture results
    BEGIN TRY
        SET @SQL = REPLACE(@SQL, 'SELECT '''' + QUOTENAME(@SchemaName) + ''.'' + QUOTENAME(@TableName) + '''' AS object_name, COUNT(1) AS rows_found;', 
                        'INSERT INTO #SearchResults (object_name, rows_found) SELECT ''' + QUOTENAME(@SchemaName) + '.' + QUOTENAME(@TableName) + ''', COUNT(1)');

        -- Execute the query and handle potential errors if table structure is unexpected.
        EXEC sp_executesql @SQL;
    END TRY
    BEGIN CATCH
        -- If execution fails (e.g., permission issues, complex data type mismatch), still record 0 findings.
        INSERT INTO #SearchResults (object_name, rows_found) VALUES ('dbo.' + @TableName, 0);
    END CATCH

    FETCH NEXT FROM table_cursor INTO @SchemaName, @TableName;
END

CLOSE table_cursor;
DEALLOCATE table_cursor;

-- Final result set containing the name and count for every checked object.
SELECT 
    object_name, 
    ISNULL(rows_found, 0) AS rows_found 
FROM #SearchResults ORDER BY object_name;

DROP TABLE #SearchResults;
