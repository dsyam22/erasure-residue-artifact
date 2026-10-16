SELECT 
    t.name AS TableName,
    s.name AS SchemaName,
    CASE WHEN t.is_ms_shipped = 1 THEN 'System' ELSE 'User' END AS TableType,
    COUNT(c.column_id) AS ColumnCount
FROM sys.tables t
JOIN sys.schemas s ON t.schema_id = s.schema_id
LEFT JOIN sys.columns c ON t.object_id = c.object_id
WHERE t.name LIKE 'customer%' OR t.name IN ('customer') -- Focus on relevant tables
GROUP BY t.name, s.name, t.is_ms_shipped
ORDER BY SchemaName, TableName;

SELECT 
    c.name AS ColumnName,
    ty.name AS DataType,
    c.max_length AS MaxLength,
    c.is_nullable AS IsNullable
FROM sys.columns c
JOIN sys.types ty ON c.system_type_id = ty.system_type_id AND c.user_type_id = ty.user_type_id
WHERE SCHEMA_NAME(c.schema_id) = 'dbo' 
AND OBJECT_ID(N'dbo.customer') IS NOT NULL -- Only show columns for the target table
ORDER BY c.column_id;

SELECT 
    s.name AS ConstraintName,
    OBJECT_NAME(s.parent_object_id) AS TableName,
    TYPE_NAME(s.type) AS ConstraintType,
    c.name AS ColumnName
FROM sys.objects s
JOIN sys.columns c ON s.parent_object_id = c.object_id AND s.column_id = c.column_id
WHERE OBJECT_NAME(s.parent_object_id) = 'customer' 
AND s.type IN ('PK', 'UQ', 'FK')
ORDER BY TableName, ConstraintType;

-- Check for any related tables or views that might reference PII columns (e.g., through foreign keys)
SELECT DISTINCT
    OBJECT_NAME(kcu.table_schema) AS ReferencingSchema,
    kcu.table_name AS ReferencingTable,
    COL_NAME(kcu.table_schema, kcu.table_name, kcu.column_id) AS ReferencedColumn
FROM sys.foreign_key_columns kfc
JOIN sys.involved_object_columns ioc ON kfc.constraint_object_id = ioc.object_id AND kfc.correlation_column_id = ioc.column_id
JOIN sys.columns c ON ioc.object_id = c.object_id AND ioc.column_id = c.column_id
WHERE OBJECT_NAME(kfc.referenced_object_id) = 'customer' 
AND (c.name IN ('full_name', 'email', 'phone') OR kcu.name IN ('full_name', 'email', 'phone')) -- Check for PII references
ORDER BY ReferencingTable;
