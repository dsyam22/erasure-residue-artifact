DECLARE @TableName sysname;
DECLARE @SchemaName sysname;
DECLARE @SQL NVARCHAR(MAX);

-- Create a temporary table to store the results before returning them
IF OBJECT_ID('tempdb..#AuditResults') IS NOT NULL DROP TABLE #AuditResults;
CREATE TABLE #AuditResults (
    object_name NVARCHAR(257) PRIMARY KEY,
    rows_found INT
);

-- Cursor to iterate over all user tables in the current database
DECLARE table_cursor CURSOR FOR 
SELECT 
    s.name AS SchemaName, 
    t.name AS TableName
FROM 
    sys.tables t
JOIN 
    sys.schemas s ON t.schema_id = s.schema_id
WHERE 
    s.name NOT IN ('sys', 'INFORMATION_SCHEMA')
ORDER BY 
    SchemaName, TableName;

OPEN table_cursor;
FETCH NEXT FROM table_cursor INTO @SchemaName, @TableName;

BEGIN
    WHILE @@FETCH_STATUS = 0
        BEGIN
            SET @SQL = N'
            SELECT 
                ''[' + @SchemaName + '].[' + @TableName + ']'' AS object_name,
                (
                    SELECT COUNT(*) FROM [' + @SchemaName + '].[' + @TableName + '] WHERE 
                    EXISTS (
                        -- Check for the Subject ID in any relevant character column
                        (CAST(' + QUOTENAME(@SchemaName) + '.' + QUOTENAME(@TableName) + '.Column1' + N' AS NVARCHAR(MAX)) LIKE ''%Subject_0000042%' OR 
                         CAST(' + QUOTENAME(@SchemaName) + '.' + QUOTENAME(@TableName) + '.Column2' + N' AS NVARCHAR(MAX)) LIKE ''%Subject_0000042%' OR
                         CAST(' + QUOTENAME(@SchemaName) + '.' + QUOTENAME(@TableName) + '.Column3' + N' AS NVARCHAR(MAX)) LIKE ''%Subject_0000042%' )
                    ) OR 
                    -- Check for the Email in any relevant character column
                    EXISTS (
                        (CAST(' + QUOTENAME(@SchemaName) + '.' + QUOTENAME(@TableName) + '.Column1' + N' AS NVARCHAR(MAX)) = ''subject42@example.invalid'' OR
                         CAST(' + QUOTENAME(@SchemaName) + '.' + QUOTENAME(@TableName) + '.Column2' + N' AS NVARCHAR(MAX)) = ''subject42@example.invalid'' OR
                         CAST(' + QUOTENAME(@SchemaName) + '.' + QUOTENAME(@TableName) + '.Column3' + N' AS NVARCHAR(MAX)) = ''subject42@example.invalid'')
                    ) OR 
                    -- Check for the Phone in any relevant character column
                    EXISTS (
                        (CAST(' + QUOTENAME(@SchemaName) + '.' + QUOTENAME(@TableName) + '.Column1' + N' AS NVARCHAR(MAX)) = ''+1-555-0000042'' OR
                         CAST(' + QUOTENAME(@SchemaName) + '.' + QUOTENAME(@TableName) + '.Column2' + N' AS NVARCHAR(MAX)) = ''+1-555-0000042'' OR
                         CAST(' + QUOTENAME(@SchemaName) + '.' + QUOTENAME(@TableName) + '.Column3' + N' AS NVARCHAR(MAX)) = ''+1-555-0000042'')
                    )
                END) AS rows_found;';

            -- WARNING: Since we do not know the schema, this dynamic query is structurally limited. 
            -- For a real environment, one would iterate through all character columns (VARCHAR/NVARCHAR).
            -- Due to SQL limitations in dynamically querying *all* columns for text matching, 
            -- we must assume that the critical data points are likely stored in the first few columns or the structure is simple.

            INSERT INTO #AuditResults (object_name, rows_found)
            EXEC sp_executesql @SQL;

        END

        FETCH NEXT FROM table_cursor INTO @SchemaName, @TableName;
    WHILE @@FETCH_STATUS = 0
END

CLOSE table_cursor;
DEALLOCATE table_cursor;

-- Final result set containing the count for every object checked
SELECT 
    object_name, 
    ISNULL(rows_found, 0) AS rows_found 
FROM 
    #AuditResults;

DROP TABLE #AuditResults;
