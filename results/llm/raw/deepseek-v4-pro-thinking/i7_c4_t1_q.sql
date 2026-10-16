SELECT DB_NAME() AS database_name, @@SERVERNAME AS server_name, GETDATE() AS inspected_at;

SELECT
    s.name AS schema_name,
    t.name AS table_name,
    t.object_id,
    SUM(CASE WHEN p.index_id IN (0, 1) THEN p.rows ELSE 0 END) AS row_count,
    t.temporal_type,
    t.temporal_type_desc,
    t.history_table_id,
    hist.name AS history_table_name
FROM sys.tables t
JOIN sys.schemas s ON t.schema_id = s.schema_id
LEFT JOIN sys.partitions p ON p.object_id = t.object_id
LEFT JOIN sys.tables hist ON t.history_table_id = hist.object_id
GROUP BY
    s.name,
    t.name,
    t.object_id,
    t.temporal_type,
    t.temporal_type_desc,
    t.history_table_id,
    hist.name
ORDER BY s.name, t.name;

SELECT
    s.name AS schema_name,
    t.name AS table_name,
    t.object_id AS table_object_id,
    c.column_id,
    c.name AS column_name,
    ty.name AS data_type,
    c.max_length,
    c.precision,
    c.scale,
    c.is_nullable,
    c.is_computed,
    c.is_identity,
    c.generated_always_type,
    c.generated_always_type_desc,
    cc.definition AS computed_column_definition
FROM sys.tables t
JOIN sys.schemas s ON t.schema_id = s.schema_id
JOIN sys.columns c ON c.object_id = t.object_id
JOIN sys.types ty ON ty.user_type_id = c.user_type_id
LEFT JOIN sys.computed_columns cc
    ON cc.object_id = c.object_id
   AND cc.column_id = c.column_id
ORDER BY s.name, t.name, c.column_id;

SELECT
    fk.name AS foreign_key_name,
    ps.name AS parent_schema,
    pt.name AS parent_table,
    pc.name AS parent_column,
    rs.name AS referenced_schema,
    rt.name AS referenced_table,
    rc.name AS referenced_column,
    fk.delete_referential_action_desc,
    fk.update_referential_action_desc
FROM sys.foreign_keys fk
JOIN sys.foreign_key_columns fkc ON fk.object_id = fkc.constraint_object_id
JOIN sys.tables pt ON fk.parent_object_id = pt.object_id
JOIN sys.schemas ps ON pt.schema_id = ps.schema_id
JOIN sys.columns pc
    ON fkc.parent_object_id = pc.object_id
   AND fkc.parent_column_id = pc.column_id
JOIN sys.tables rt ON fk.referenced_object_id = rt.object_id
JOIN sys.schemas rs ON rt.schema_id = rs.schema_id
JOIN sys.columns rc
    ON fkc.referenced_object_id = rc.object_id
   AND fkc.referenced_column_id = rc.column_id
ORDER BY fk.name, fkc.constraint_column_id;

SELECT
    s.name AS schema_name,
    o.name AS object_name,
    o.type_desc,
    m.definition,
    tr.parent_id,
    ps.name AS trigger_parent_schema,
    pt.name AS trigger_parent_table
FROM sys.sql_modules m
JOIN sys.objects o ON m.object_id = o.object_id
JOIN sys.schemas s ON o.schema_id = s.schema_id
LEFT JOIN sys.triggers tr ON tr.object_id = o.object_id
LEFT JOIN sys.tables pt ON tr.parent_id = pt.object_id
LEFT JOIN sys.schemas ps ON pt.schema_id = ps.schema_id
WHERE o.is_ms_shipped = 0
ORDER BY s.name, o.name;

SELECT
    s.name AS schema_name,
    sn.name AS synonym_name,
    sn.base_object_name
FROM sys.synonyms sn
JOIN sys.schemas s ON sn.schema_id = s.schema_id
ORDER BY s.name, sn.name;

SELECT
    s.name AS schema_name,
    t.name AS table_name,
    dc.name AS default_constraint_name,
    dc.definition
FROM sys.default_constraints dc
JOIN sys.tables t ON dc.parent_object_id = t.object_id
JOIN sys.schemas s ON t.schema_id = s.schema_id
ORDER BY s.name, t.name, dc.name;
