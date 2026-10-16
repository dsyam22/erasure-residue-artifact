DECLARE @TableName sysname;
DECLARE @SchemaName sysname;
DECLARE @SQL NVARCHAR(MAX);

-- Temporary table to hold the results: object_name, rows_found
CREATE TABLE #SearchResults (
    object_name nvarchar(50),
    rows_found int
);

-- Cursor to iterate through all user-defined tables in the current database
DECLARE TableCursor CURSOR FOR
SELECT 
    s.name AS SchemaName, 
    t.name AS TableName
FROM sys.tables t
JOIN sys.schemas s ON t.schema_id = s.schema_id
WHERE t.is_ms_shipped = 0;

OPEN TableCursor;
FETCH NEXT FROM TableCursor INTO @SchemaName, @TableName;

BEGIN TRANSACTION; -- Use transaction scope for cleanup robustness

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @SQL = N'
        SELECT 
            ''[' + CAST(@SchemaName AS NVARCHAR(128)) + '].[' + CAST(@TableName AS NVARCHAR(128)) + ']'' AS object_name,
            ISNULL((SELECT COUNT(T.*) FROM [' + QUOTENAME(@SchemaName) + '].[' + QUOTENAME(@TableName) + ']'] T WHERE 
                -- Check for the specific customer ID value (assuming it might be stored as text or integer)
                CAST(T.[customer_id] AS NVARCHAR(50)) = ''42'' OR
                T.[full_name] LIKE ''%Subject_0000042%'' OR
                T.[email] LIKE ''%subject42@example.invalid%'' OR
                T.[phone] LIKE ''%1-555-0000042%'' 
            ), 0) AS rows_found;';

    -- Execute the count and insert results into the temporary table
    INSERT INTO #SearchResults (object_name, rows_found)
    EXEC sp_executesql @SQL;

    FETCH NEXT FROM TableCursor INTO @SchemaName, @TableName;
END

CLOSE TableCursor;
DEALLOCATE TableCursor;

-- Final cleanup and presentation of the required single result set
SELECT 
    object_name,
    rows_found
FROM #SearchResults
ORDER BY object_name;

-- Clean up temporary table
DROP TABLE #SearchResults;
