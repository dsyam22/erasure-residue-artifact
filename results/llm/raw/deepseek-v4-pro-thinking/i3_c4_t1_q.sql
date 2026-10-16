SELECT DB_NAME() AS current_database;

SELECT 
    s.name AS schema_name,
    t.name AS table_name,
    t.temporal_type_desc,
    t.is_tracked_by_cdc,
    hs.name AS history_schema_name,
    ht.name AS history_table_name,
    p.row_count
FROM sys.tables t
JOIN sys.schemas s ON t.schema_id = s.schema_id
LEFT JOIN sys.tables ht ON t.history_table_id = ht.object_id
LEFT JOIN sys.schemas hs ON ht.schema_id = hs.schema_id
LEFT JOIN (
    SELECT object_id, SUM(rows) AS row_count
    FROM sys.partitions
    WHERE index_id IN (0,1)
    GROUP BY object_id
) p ON p.object_id = t.object_id
ORDER BY s.name, t.name;

SELECT 
    s.name AS schema_name,
    t.name AS table_name,
    c.column_id,
    c.name AS column_name,
    ty.name AS data_type,
    c.max_length,
    c.precision,
    c.scale,
    c.is_nullable,
    c.is_identity,
    c.is_computed,
    c.generated_always_type_desc
FROM sys.columns c
JOIN sys.tables t ON c.object_id = t.object_id
JOIN sys.schemas s ON t.schema_id = s.schema_id
JOIN sys.types ty ON c.user_type_id = ty.user_type_id
ORDER BY s.name, t.name, c.column_id;

SELECT 
    s.name AS schema_name,
    t.name AS table_name,
    c.name AS column_name,
    cc.definition,
    cc.is_persisted
FROM sys.computed_columns cc
JOIN sys.columns c ON cc.object_id = c.object_id AND cc.column_id = c.column_id
JOIN sys.tables t ON c.object_id = t.object_id
JOIN sys.schemas s ON t.schema_id = s.schema_id
ORDER BY s.name, t.name, c.column_id;

SELECT 
    fk.name AS foreign_key_name,
    sp.name AS parent_schema,
    tp.name AS parent_table,
    sr.name AS referenced_schema,
    tr.name AS referenced_table,
    fk.delete_referential_action_desc,
    fk.update_referential_action_desc
FROM sys.foreign_keys fk
JOIN sys.tables tp ON fk.parent_object_id = tp.object_id
JOIN sys.schemas sp ON tp.schema_id = sp.schema_id
JOIN sys.tables tr ON fk.referenced_object_id = tr.object_id
JOIN sys.schemas sr ON tr.schema_id = sr.schema_id
ORDER BY fk.name;

SELECT 
    s.name AS schema_name,
    t.name AS table_name,
    tr.name AS trigger_name,
    tr.is_disabled,
    tr.is_instead_of_trigger,
    m.definition
FROM sys.triggers tr
JOIN sys.tables t ON tr.parent_id = t.object_id
JOIN sys.schemas s ON t.schema_id = s.schema_id
JOIN sys.sql_modules m ON tr.object_id = m.object_id
ORDER BY s.name, t.name, tr.name;
