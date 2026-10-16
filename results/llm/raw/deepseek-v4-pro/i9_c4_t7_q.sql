SELECT 
    SCHEMA_NAME(t.schema_id) AS schema_name,
    t.name AS table_name,
    c.name AS column_name,
    ty.name AS data_type,
    c.max_length,
    c.is_nullable
FROM sys.tables t
INNER JOIN sys.columns c ON t.object_id = c.object_id
INNER JOIN sys.types ty ON c.user_type_id = ty.user_type_id
WHERE SCHEMA_NAME(t.schema_id) = 'dbo'
ORDER BY t.name, c.column_id;

SELECT 
    SCHEMA_NAME(t.schema_id) AS schema_name,
    t.name AS table_name,
    i.name AS index_name,
    i.type_desc,
    i.is_unique,
    i.is_primary_key
FROM sys.tables t
INNER JOIN sys.indexes i ON t.object_id = i.object_id
WHERE SCHEMA_NAME(t.schema_id) = 'dbo'
ORDER BY t.name, i.index_id;

SELECT 
    SCHEMA_NAME(t.schema_id) AS schema_name,
    t.name AS table_name,
    SUM(p.rows) AS row_count
FROM sys.tables t
INNER JOIN sys.partitions p ON t.object_id = p.object_id AND p.index_id IN (0, 1)
WHERE SCHEMA_NAME(t.schema_id) = 'dbo'
GROUP BY SCHEMA_NAME(t.schema_id), t.name
ORDER BY t.name;

SELECT 
    OBJECT_NAME(fk.parent_object_id) AS referencing_table,
    COL_NAME(fkc.parent_object_id, fkc.parent_column_id) AS referencing_column,
    OBJECT_NAME(fk.referenced_object_id) AS referenced_table,
    COL_NAME(fkc.referenced_object_id, fkc.referenced_column_id) AS referenced_column
FROM sys.foreign_keys fk
INNER JOIN sys.foreign_key_columns fkc ON fk.object_id = fkc.constraint_object_id
WHERE SCHEMA_NAME(OBJECT_SCHEMA_NAME(fk.parent_object_id)) = 'dbo'
   OR SCHEMA_NAME(OBJECT_SCHEMA_NAME(fk.referenced_object_id)) = 'dbo'
ORDER BY referencing_table, referencing_column;
