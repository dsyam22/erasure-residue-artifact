SELECT 
    SCHEMA_NAME(t.schema_id) AS schema_name,
    t.name AS table_name,
    c.name AS column_name,
    TYPE_NAME(c.user_type_id) AS data_type,
    c.max_length,
    c.is_nullable
FROM sys.tables t
JOIN sys.columns c ON t.object_id = c.object_id
WHERE t.is_ms_shipped = 0
ORDER BY schema_name, table_name, c.column_id;

SELECT 
    SCHEMA_NAME(s.schema_id) AS schema_name,
    s.name AS view_name,
    m.definition
FROM sys.views s
JOIN sys.sql_modules m ON s.object_id = m.object_id
WHERE s.is_ms_shipped = 0
ORDER BY schema_name, view_name;

SELECT 
    SCHEMA_NAME(p.schema_id) AS schema_name,
    p.name AS procedure_name,
    m.definition
FROM sys.procedures p
JOIN sys.sql_modules m ON p.object_id = m.object_id
WHERE p.is_ms_shipped = 0
ORDER BY schema_name, procedure_name;

SELECT 
    SCHEMA_NAME(fk.schema_id) AS schema_name,
    fk.name AS foreign_key_name,
    OBJECT_NAME(fk.parent_object_id) AS referencing_table,
    COL_NAME(fkc.parent_object_id, fkc.parent_column_id) AS referencing_column,
    OBJECT_NAME(fk.referenced_object_id) AS referenced_table,
    COL_NAME(fkc.referenced_object_id, fkc.referenced_column_id) AS referenced_column
FROM sys.foreign_keys fk
JOIN sys.foreign_key_columns fkc ON fk.object_id = fkc.constraint_object_id
ORDER BY schema_name, foreign_key_name;

SELECT 
    SCHEMA_NAME(t.schema_id) AS schema_name,
    t.name AS table_name,
    i.name AS index_name,
    i.type_desc AS index_type,
    COL_NAME(ic.object_id, ic.column_id) AS column_name
FROM sys.indexes i
JOIN sys.index_columns ic ON i.object_id = ic.object_id AND i.index_id = ic.index_id
JOIN sys.tables t ON i.object_id = t.object_id
WHERE i.is_hypothetical = 0
ORDER BY schema_name, table_name, index_name, ic.key_ordinal;
