SELECT DB_NAME() AS database_name, @@SERVERNAME AS server_name;

SELECT 
    s.name AS schema_name,
    t.name AS table_name,
    t.object_id,
    t.temporal_type,
    t.temporal_type_desc,
    t.history_table_id,
    hs.name AS history_schema_name,
    ht.name AS history_table_name
FROM sys.tables AS t
JOIN sys.schemas AS s ON t.schema_id = s.schema_id
LEFT JOIN sys.tables AS ht ON t.history_table_id = ht.object_id
LEFT JOIN sys.schemas AS hs ON ht.schema_id = hs.schema_id
ORDER BY s.name, t.name;

SELECT 
    s.name AS schema_name,
    t.name AS table_name,
    c.column_id,
    c.name AS column_name,
    ty.name AS data_type,
    st.name AS system_data_type,
    c.max_length,
    c.precision,
    c.scale,
    c.collation_name,
    c.is_nullable,
    c.is_identity,
    c.generated_always_type,
    c.generated_always_type_desc,
    c.is_hidden
FROM sys.tables AS t
JOIN sys.schemas AS s ON t.schema_id = s.schema_id
JOIN sys.columns AS c ON t.object_id = c.object_id
JOIN sys.types AS ty ON c.user_type_id = ty.user_type_id
JOIN sys.types AS st ON c.system_type_id = st.user_type_id
ORDER BY s.name, t.name, c.column_id;

SELECT 
    fk.name AS fk_name,
    OBJECT_SCHEMA_NAME(fk.parent_object_id) AS parent_schema,
    OBJECT_NAME(fk.parent_object_id) AS parent_table,
    pc.name AS parent_column,
    OBJECT_SCHEMA_NAME(fk.referenced_object_id) AS referenced_schema,
    OBJECT_NAME(fk.referenced_object_id) AS referenced_table,
    rc.name AS referenced_column
FROM sys.foreign_keys AS fk
JOIN sys.foreign_key_columns AS fkc ON fk.object_id = fkc.constraint_object_id
JOIN sys.columns AS pc ON fkc.parent_object_id = pc.object_id AND fkc.parent_column_id = pc.column_id
JOIN sys.columns AS rc ON fkc.referenced_object_id = rc.object_id AND fkc.referenced_column_id = rc.column_id
ORDER BY fk.name;

SELECT 
    p.object_id,
    s.name AS schema_name,
    t.name AS table_name,
    p.name AS period_name,
    p.period_type_desc,
    sc.name AS start_column,
    ec.name AS end_column
FROM sys.periods AS p
JOIN sys.tables AS t ON p.object_id = t.object_id
JOIN sys.schemas AS s ON t.schema_id = s.schema_id
JOIN sys.columns AS sc ON p.object_id = sc.object_id AND p.start_column_id = sc.column_id
JOIN sys.columns AS ec ON p.object_id = ec.object_id AND p.end_column_id = ec.column_id
ORDER BY s.name, t.name, p.name;

SELECT 
    s.name AS schema_name,
    t.name AS table_name,
    SUM(ps.row_count) AS row_count
FROM sys.tables AS t
JOIN sys.schemas AS s ON t.schema_id = s.schema_id
JOIN sys.dm_db_partition_stats AS ps ON t.object_id = ps.object_id AND ps.index_id IN (0,1)
GROUP BY s.name, t.name
ORDER BY s.name, t.name;
