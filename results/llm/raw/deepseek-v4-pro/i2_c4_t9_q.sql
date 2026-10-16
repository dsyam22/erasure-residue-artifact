SELECT 
    SCHEMA_NAME(t.schema_id) AS schema_name,
    t.name AS table_name,
    c.name AS column_name,
    ty.name AS data_type,
    c.max_length,
    c.is_nullable,
    c.is_identity,
    dc.definition AS default_constraint,
    cc.definition AS check_constraint,
    fk.name AS fk_name,
    OBJECT_NAME(fk.referenced_object_id) AS referenced_table,
    COL_NAME(fc.referenced_object_id, fc.referenced_column_id) AS referenced_column
FROM sys.tables t
INNER JOIN sys.columns c ON t.object_id = c.object_id
INNER JOIN sys.types ty ON c.user_type_id = ty.user_type_id
LEFT JOIN sys.default_constraints dc ON c.default_object_id = dc.object_id
LEFT JOIN sys.check_constraints cc ON c.column_id = cc.parent_column_id AND cc.parent_object_id = t.object_id
LEFT JOIN sys.foreign_key_columns fc ON t.object_id = fc.parent_object_id AND c.column_id = fc.parent_column_id
LEFT JOIN sys.foreign_keys fk ON fc.constraint_object_id = fk.object_id
WHERE t.is_ms_shipped = 0
ORDER BY schema_name, table_name, c.column_id;
