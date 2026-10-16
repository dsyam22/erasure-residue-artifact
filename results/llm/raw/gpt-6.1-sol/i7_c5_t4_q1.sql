-- QUERY
SELECT
    s.name AS schema_name,
    t.name AS table_name,
    t.temporal_type_desc,
    hs.name AS history_schema_name,
    ht.name AS history_table_name,
    t.is_tracked_by_cdc,
    t.is_memory_optimized,
    t.is_external,
    c.column_id,
    c.name AS column_name,
    ty.name AS data_type
FROM llm_i7.sys.tables AS t
JOIN llm_i7.sys.schemas AS s ON s.schema_id = t.schema_id
LEFT JOIN llm_i7.sys.tables AS ht ON ht.object_id = t.history_table_id
LEFT JOIN llm_i7.sys.schemas AS hs ON hs.schema_id = ht.schema_id
JOIN llm_i7.sys.columns AS c ON c.object_id = t.object_id
JOIN llm_i7.sys.types AS ty ON ty.user_type_id = c.user_type_id
ORDER BY s.name, t.name, c.column_id;
