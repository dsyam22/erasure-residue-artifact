SELECT 
    DB_NAME() AS database_name,
    s.name AS schema_name,
    t.name AS table_name,
    t.object_id,
    t.temporal_type_desc,
    hist.name AS history_table_name,
    t.history_table_id,
    ps.row_count
FROM sys.tables AS t
INNER JOIN sys.schemas AS s ON t.schema_id = s.schema_id
LEFT JOIN sys.tables AS hist ON t.history_table_id = hist.object_id
LEFT JOIN (
    SELECT object_id, SUM(rows) AS row_count
    FROM sys.dm_db_partition_stats
    WHERE index_id IN (0,1)
    GROUP BY object_id
) AS ps ON ps.object_id = t.object_id
WHERE t.is_ms_shipped = 0
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
FROM sys.columns AS c
INNER JOIN sys.tables AS t ON c.object_id = t.object_id
INNER JOIN sys.schemas AS s ON t.schema_id = s.schema_id
INNER JOIN sys.types AS ty ON c.user_type_id = ty.user_type_id
WHERE t.is_ms_shipped = 0
ORDER BY s.name, t.name, c.column_id;

SELECT 
    fk.name AS fk_name,
    ps.name AS parent_schema,
    pt.name AS parent_table,
    pc.name AS parent_column,
    rs.name AS referenced_schema,
    rt.name AS referenced_table,
    rc.name AS referenced_column
FROM sys.foreign_keys AS fk
INNER JOIN sys.foreign_key_columns AS fkc ON fk.object_id = fkc.constraint_object_id
INNER JOIN sys.tables AS pt ON fk.parent_object_id = pt.object_id
INNER JOIN sys.schemas AS ps ON pt.schema_id = ps.schema_id
INNER JOIN sys.columns AS pc ON fkc.parent_object_id = pc.object_id AND fkc.parent_column_id = pc.column_id
INNER JOIN sys.tables AS rt ON fk.referenced_object_id = rt.object_id
INNER JOIN sys.schemas AS rs ON rt.schema_id = rs.schema_id
INNER JOIN sys.columns AS rc ON fkc.referenced_object_id = rc.object_id AND fkc.referenced_column_id = rc.column_id
ORDER BY fk.name;

SELECT 
    s.name AS schema_name,
    v.name AS view_name,
    m.definition
FROM sys.views AS v
INNER JOIN sys.schemas AS s ON v.schema_id = s.schema_id
LEFT JOIN sys.sql_modules AS m ON v.object_id = m.object_id
WHERE v.is_ms_shipped = 0
ORDER BY s.name, v.name;

SELECT 
    s.name AS schema_name,
    syn.name AS synonym_name,
    syn.base_object_name
FROM sys.synonyms AS syn
INNER JOIN sys.schemas AS s ON syn.schema_id = s.schema_id
ORDER BY s.name, syn.name;
