SELECT 
    t.name AS TableName, 
    c.name AS ColumnName, 
    ty.name AS DataType, 
    c.max_length AS MaxLength, 
    CASE WHEN c.is_nullable = 1 THEN 'YES' ELSE 'NO' END AS IsNullable
FROM sys.columns c
JOIN sys.tables t ON c.object_id = t.object_id
JOIN sys.types ty ON c.system_type_id = ty.system_type_id AND c.user_type_id = ty.user_type_id
WHERE SCHEMA_NAME(t.schema_id) = 'dbo' 
ORDER BY TableName, c.column_id;

-- Check Foreign Key Constraints referencing or originating from the customer table
SELECT 
    fk.name AS ForeignKeyName,
    OBJECT_NAME(fk.parent_object_id) AS ParentTable,
    COL_NAME(fkc.parent_object_id, fkc.parent_column_id) AS ParentColumn,
    OBJECT_NAME(fk.referenced_object_id) AS ReferencedTable,
    COL_NAME(fkc.referenced_object_id, fkc.referenced_column_id) AS ReferencedColumn
FROM sys.foreign_keys fk
JOIN sys.foreign_key_columns fkc 
  ON fk.object_id = fkc.constraint_object_id
WHERE OBJECT_NAME(fk.parent_object_id) IN ('dbo.customer') OR OBJECT_NAME(fk.referenced_object_id) = 'dbo.customer';

-- Check for any potential history or log tables that might contain PII 
-- (assuming standard naming conventions like *_history or *log)
SELECT 
    t.name AS PotentialHistoryTable,
    c.namesplit AS ColumnsFound
FROM sys.tables t
JOIN sys.columns c ON t.object_id = c.object_id
WHERE OBJECT_NAME(t.object_id) LIKE '%history%' OR OBJECT_NAME(t.object_id) LIKE '%log%';
