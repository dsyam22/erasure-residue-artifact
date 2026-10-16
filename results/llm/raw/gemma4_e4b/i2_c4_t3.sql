SET NOCOUNT ON;

-- Temporary table to store results (Object Name and Row Count)
IF OBJECT_ID('tempdb..#PII_Checks') IS NOT NULL DROP TABLE #PII_Checks;
CREATE TABLE #PII_Checks (
    object_name NVARCHAR(256),
    rows_found INT
);

-- Cursor to iterate through all user tables in the dbo schema
DECLARE @TableName sysname;
DECLARE table_cursor CURSOR FOR
SELECT name 
FROM sys.tables 
WHERE is_ms_shipped = 0 AND SCHEMA_NAME(schema_id) = 'dbo';

OPEN table_cursor;
FETCH NEXT FROM table_cursor INTO @TableName;

WHILE @@FETCH_STATUS = 0
BEGIN
    DECLARE @SQL NVARCHAR(MAX);
    SET @SQL = N'
        IF EXISTS (SELECT 1 FROM (' + QUOTENAME(@TableName) + ') WHERE 1=1)
        BEGIN
            -- Check for Customer ID match (assuming integer columns like customer_id exist)
            INSERT INTO #PII_Checks (object_name, rows_found)
            SELECT 
                ''' + @TableName + ''', 
                COUNT(CASE WHEN CONVERT(INT, [customer_id]) = 42 THEN 1 END)
            FROM ' + QUOTENAME(@TableName) + ';

            -- Check for Full Name match (assuming string columns like full_name exist)
            INSERT INTO #PII_Checks (object_name, rows_found)
            SELECT 
                ''' + @TableName + ''', 
                COUNT(CASE WHEN [full_name] = ''Subject_0000042'' THEN 1 END)
            FROM ' + QUOTENAME(@TableName) + ';

            -- Check for Email match (assuming string columns like email exist)
            INSERT INTO #PII_Checks (object_name, rows_found)
            SELECT 
                ''' + @TableName + ''', 
                COUNT(CASE WHEN [email] = ''subject42@example.invalid'' THEN 1 END)
            FROM ' + QUOTENAME(@TableName) + ';

            -- Check for Phone match (assuming string columns like phone exist)
            INSERT INTO #PII_Checks (object_name, rows_found)
            SELECT 
                ''' + @TableName + ''', 
                COUNT(CASE WHEN [phone] = ''+1-555-0000042'' THEN 1 END)
            FROM ' + QUOTENAME(@TableName) + ';

        END;';

    -- Execute the dynamic SQL check for the current table
    EXEC sp_executesql @SQL;

    FETCH NEXT FROM table_cursor INTO @TableName;
END

CLOSE table_cursor;
DEALLOCATE table_cursor;

-- Final result set generation: Aggregate counts per object name.
SELECT 
    object_name, 
    SUM(rows_found) AS rows_found
FROM #PII_Checks
GROUP BY object_name
ORDER BY object_name;

DROP TABLE #PII_Checks;
