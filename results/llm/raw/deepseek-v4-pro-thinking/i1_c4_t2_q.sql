SELECT 
    @@SERVERNAME AS server_name,
    DB_NAME() AS current_db,
    DB_ID('llm_i1') AS llm_i1_database_id;

SELECT 
    s.name AS schema_name,
    t.name AS table_name,
    t.object_id,
    t.create_date,
    t.modify_date,
    SUM(p.rows) AS row_count
FROM llm_i1.sys.tables AS t
JOIN llm_i1.sys.schemas AS s 
    ON t.schema_id = s.schema_id
JOIN llm_i1.sys.partitions AS p 
    ON t.object_id = p.object_id 
   AND p.index_id IN (0,1)
WHERE t.is_ms_shipped = 0
GROUP BY s.name, t.name, t.object_id, t.create_date, t.modify_date
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
    c.is_identity,
    c.is_computed,
    cc.definition AS computed_definition
FROM llm_i1.sys.columns AS c
JOIN llm_i1.sys.objects AS o 
    ON c.object_id = o.object_id
JOIN llm_i1.sys.schemas AS s 
    ON o.schema_id = s.schema_id
LEFT JOIN llm_i1.sys.computed_columns AS cc 
    ON c.object_id = cc.object_id 
   AND c.column_id = cc.column_id
WHERE o.is_ms_shipped = 0
  AND o.type IN ('U','V')
ORDER BY s.name, o.name, c.column_id;

SELECT 
    s.name AS schema_name,
    o.name AS object_name,
    o.type_desc,
    m.definition
FROM llm_i1.sys.sql_modules AS m
JOIN llm_i1.sys.objects AS o 
    ON m.object_id = o.object_id
JOIN llm_i1.sys.schemas AS s 
    ON o.schema_id = s.schema_id
WHERE o.is_ms_shipped = 0
ORDER BY o.type_desc, s.name, o.name;

SELECT 
    s.name AS schema_name,
    sn.name AS synonym_name,
    sn.base_object_name
FROM llm_i1.sys.synonyms AS sn
JOIN llm_i1.sys.schemas AS s 
    ON sn.schema_id = s.schema_id
ORDER BY s.name, sn.name;

SELECT 
    ps.name AS parent_schema,
    pt.name AS parent_table,
    rs.name AS referenced_schema,
    rt.name AS referenced_table,
    fk.name AS foreign_key_name,
    fk.is_disabled
FROM llm_i1.sys.foreign_keys AS fk
JOIN llm_i1.sys.tables AS pt 
    ON fk.parent_object_id = pt.object_id
JOIN llm_i1.sys.schemas AS ps 
    ON pt.schema_id = ps.schema_id
JOIN llm_i1.sys.tables AS rt 
    ON fk.referenced_object_id = rt.object_id
JOIN llm_i1.sys.schemas AS rs 
    ON rt.schema_id = rs.schema_id
WHERE fk.is_ms_shipped = 0
ORDER BY ps.name, pt.name, fk.name;
