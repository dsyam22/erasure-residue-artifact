SET NOCOUNT ON;

-- Temporary table to store the results: object_name and row count found for the subject.
IF OBJECT_ID('tempdb..#DetectionResults') IS NOT NULL DROP TABLE #DetectionResults;

CREATE TABLE #DetectionResults (
    object_name NVARCHAR(256),
    rows_found INT
);

DECLARE @TableName SYSNAME;
DECLARE @SchemaName SYSNAME = 'dbo'; -- Assuming standard schema
DECLARE @SQL NVARCHAR(MAX) = N'';

-- Define the subject's data for comparison (using parameterized values in the logic)
DECLARE @SubjectID INT = 42;
DECLARE @FullName NVARCHAR(100) = 'Subject_0000042';
DECLARE @Email NVARCHAR(100) = 'subject42@example.invalid';
DECLARE @Phone NVARCHAR(50) = '+1-555-0000042';

-- Cursor to iterate over all user tables in the database
DECLARE TableCursor CURSOR FOR 
    SELECT name FROM sys.tables WHERE schema_id = SCHEMA_ID(@SchemaName);

OPEN TableCursor;
FETCH NEXT FROM TableCursor INTO @TableName;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @SQL = N'';
    -- Build a complex SELECT query to check for the existence of the PII combination.
    -- This attempts to check common identifier columns (ID, name, email, phone) across all text/numeric types in the current table.
    -- We use COUNT(*) and wrap it in CTE logic or SELECT INTO to capture the count dynamically.

    SET @SQL = N'
        INSERT INTO #DetectionResults (object_name, rows_found)
        SELECT 
            ''' + QUOTENAME(@SchemaName) + '.' + QUOTENAME(@TableName) + ''',
            COUNT(T.*)
        FROM ' + QUOTENAME(@SchemaName) + '.' + QUOTENAME(@TableName) + ' AS T
        WHERE 
            -- Priority Check: Exact match on ID (if integer column exists)
            EXISTS (SELECT 1 FROM sys.columns c WHERE c.object_id = OBJECT_ID(''' + QUOTENAME(@SchemaName) + '.' + QUOTENAME(@TableName) + ''') AND c.name LIKE ''customer_id'' AND T.CAST(T.''+(SELECT TOP 1 name FROM sys.columns WHERE object_id = OBJECT_ID(' + QUOTENAME(@SchemaName) + '.' + QUOTENAME(@TableName) + ') ORDER BY column_id) +''' AS INT) <= @SubjectId
            OR 
            -- Check for Name match (case-insensitive LIKE search)
            (LOWER(T.''+(SELECT TOP 1 name FROM sys.columns WHERE object_id = OBJECT_ID(' + QUOTENAME(@SchemaName) + '.' + QUOTENAME(@TableName) + ') ORDER BY column_id) +''' ) LIKE LOWER(@FullName) 
            OR 
            -- Check for Email match (case-insensitive LIKE search)
            (LOWER(T.''+(SELECT TOP 1 name FROM sys.columns WHERE object_id = OBJECT_ID(' + QUOTENAME(@SchemaName) + '.' + QUOTENAME(@TableName) + ') ORDER BY column_id) +''' ) LIKE LOWER(@Email)
             -- Check for Phone match (LIKE search, handles formatting variations)
            OR (T.''+(SELECT TOP 1 name FROM sys.columns WHERE object_id = OBJECT_ID(' + QUOTENAME(@SchemaName) + '.' + QUOTENAME(@TableName) + ') ORDER BY column_id) +''' ) LIKE @Phone;';

    -- Execute the dynamic SQL, passing parameters safely
    EXEC sp_executesql 
        @SQL, 
        N'@SubjectId INT, @FullName NVARCHAR(100), @Email NVARCHAR(100), @Phone NVARCHAR(50)', 
        @SubjectId = @SubjectID, 
        @FullName = @FullName, 
        @Email = @Email, 
        @Phone = @Phone;

    FETCH NEXT FROM TableCursor INTO @TableName;
END

CLOSE TableCursor;
DEALLOCATE TableCursor;

-- Final result set: Select all results from the temp table.
SELECT object_name, rows_found FROM #DetectionResults ORDER BY object_name;

DROP TABLE #DetectionResults;
