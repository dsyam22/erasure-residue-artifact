SELECT DB_NAME() AS current_database;

SELECT
    s.name AS schema_name,
    t.name AS table_name,
    t.temporal_type_desc,
    t.ledger_type_desc,
    t.is_memory_optimized,
    t.is_tracked_by_cdc,
    hs.name AS history_schema_name,
    ht.name AS history_table_name,
    t.history_table_id
FROM sys.tables t
JOIN sys.schemas s ON t.schema_id = s.schema_id
LEFT JOIN sys.tables ht ON t.history_table_id = ht.object_id
LEFT JOIN sys.schemas hs ON ht.schema_id = hs.schema_id
ORDER BY s.name, t.name;

SELECT
    s.name AS schema_name,
    o.name AS object_name,
    o.type_desc,
    c.column_id,
    c.name AS column_name,
    TYPE_NAME(c.user_type_id) AS data_type,
    c.max_length,
    c.precision,
    c.scale,
    c.is_nullable,
    c.is_computed,
    c.is_identity,
    c.generated_always_type_desc,
    c.is_hidden
FROM sys.objects o
JOIN sys.schemas s ON o.schema_id = s.schema_id
JOIN sys.columns c ON o.object_id = c.object_id
WHERE o.type IN ('U','V')
ORDER BY s.name, o.name, c.column_id;

SELECT
    fk.name AS fk_name,
    ps.name AS parent_schema,
    pt.name AS parent_table,
    STRING_AGG(pc.name, ', ') WITHIN GROUP (ORDER BY fkc.constraint_column_id) AS parent_columns,
    rs.name AS referenced_schema,
    rt.name AS referenced_table,
    STRING_AGG(rc.name, ', ') WITHIN GROUP (ORDER BY fkc.constraint_column_id) AS referenced_columns,
    fk.delete_referential_action_desc
FROM sys.foreign_keys fk
JOIN sys.foreign_key_columns fkc ON fk.object_id = fkc.constraint_object_id
JOIN sys.tables pt ON fk.parent_object_id = pt.object_id
JOIN sys.schemas ps ON pt.schema_id = ps.schema_id
JOIN sys.columns pc ON fkc.parent_object_id = pc.object_id AND fkc.parent_column_id = pc.column_id
JOIN sys.tables rt ON fk.referenced_object_id = rt.object_id
JOIN sys.schemas rs ON rt.schema_id = rs.schema_id
JOIN sys.columns rc ON fkc.referenced_object_id = rc.object_id AND fkc.referenced_column_id = rc.column_id
GROUP BY fk.name, ps.name, pt.name, rs.name, rt.name, fk.delete_referential_action_desc
ORDER BY fk.name;

SELECT
    s.name AS schema_name,
    v.name AS view_name,
    CASE 
        WHEN EXISTS (SELECT 1 FROM sys.indexes i WHERE i.object_id = v.object_id AND i.index_id > 0) 
        THEN 1 
        ELSE 0 
    END AS has_index
FROM sys.views v
JOIN sys.schemas s ON v.schema_id = s.schema_id
ORDER BY s.name, v.name;
