-- 1. List all tables and their primary keys within the database scope
SELECT
    t.name AS TableName,
    c.name AS ColumnName,
    ty.name AS DataType,
    c.max_length AS MaxLength,
    c.is_nullable AS IsNullable,
    CASE WHEN i.is_primary_key = 1 THEN 'PK' ELSE '' END AS KeyStatus
FROM 
    sys.tables t
INNER JOIN 
    sys.columns c ON t.object_id = c.object_id
INNER JOIN 
    sys.types ty ON c.system_type_id = ty.system_type_id AND c.user_type_id = ty.user_type_id
LEFT JOIN 
    sys.key_column_usage kcu ON t.object_id = kcu.object_id AND c.column_id = kcu.column_id
INNER JOIN 
    sys.indexes i ON t.object_id = i.object_id AND kcu.index_id = i.index_id
WHERE 
    t.schema_name = 'dbo'
ORDER BY 
    TableName, i.is_primary_key DESC;

-- 2. Check row counts for the relevant tables (to assess data volume)
SELECT 
    table_name, 
    ROUND(row_count, 0) AS RowCount 
FROM 
    sys.partitions 
WHERE 
    object_id IN (OBJECT_ID('dbo.customer'), OBJECT_ID('dbo.member'))
GROUP BY 
    table_name, 
    SUM(row_count)
ORDER BY 
    table_name;

-- 3. Examine the structure and data types of the key tables
SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME IN ('customer', 'member') AND TABLE_SCHEMA = 'dbo' ORDER BY TABLE_NAME, ORDINAL_POSITION;
