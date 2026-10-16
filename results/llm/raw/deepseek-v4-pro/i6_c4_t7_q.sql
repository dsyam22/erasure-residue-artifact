SELECT 
    SCHEMA_NAME(schema_id) AS schema_name,
    name AS table_name,
    column_id,
    name AS column_name,
    type_name(user_type_id) AS data_type,
    max_length,
    is_nullable,
    is_identity,
    is_computed
FROM sys.columns
WHERE object_id IN (
    SELECT object_id 
    FROM sys.tables
)
ORDER BY schema_name, table_name, column_id;
