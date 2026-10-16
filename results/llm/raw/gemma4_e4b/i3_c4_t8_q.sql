-- Check general schema information to identify all potential columns containing personal identifiable information (PII).
SELECT 
    TABLE_SCHEMA, 
    TABLE_NAME, 
    COLUMN_NAME, 
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH
FROM 
    INFORMATION_SCHEMA.COLUMNS
WHERE 
    -- Broad search for common PII column naming conventions (case insensitive)
    LOWER(COLUMN_NAME) LIKE '%name%' OR 
    LOWER(COLUMN_NAME) LIKE '%email%' OR 
    LOWER(COLUMN_NAME) LIKE '%phone%';

-- Verify the explicit structures of the two tables involved in the erasure process.
SELECT 'dbo.customer' AS TargetTable, COUNT(*) AS ColumnCount FROM sys.columns WHERE object_id = OBJECT_ID('dbo.customer')
UNION ALL
SELECT 'dbo.member' AS TargetTable, COUNT(*) AS ColumnCount FROM sys.columns WHERE object_id = OBJECT_ID('dbo.member');

-- Check for any other tables that might contain PII based on the previous column name analysis (optional safety check).
-- This query returns all columns with potentially sensitive names across *all* user tables.
SELECT 
    TABLE_SCHEMA, 
    TABLE_NAME, 
    COLUMN_NAME
FROM 
    INFORMATION_SCHEMA.COLUMNS
WHERE 
    LOWER(COLUMN_NAME) LIKE '%name%' OR 
    LOWER(COLUMN_NAME) LIKE '%email%' OR 
    LOWER(COLUMN_NAME) LIKE '%phone%';
