SELECT 
    s.name AS schema_name,
    t.name AS table_name,
    c.name AS column_name,
    ty.name AS data_type,
    c.max_length,
    c.is_nullable
FROM sys.tables t
INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
INNER JOIN sys.columns c ON t.object_id = c.object_id
INNER JOIN sys.types ty ON c.user_type_id = ty.user_type_id
WHERE t.is_ms_shipped = 0
ORDER BY s.name, t.name, c.column_id;

SELECT 
    s.name AS schema_name,
    v.name AS view_name,
    v.definition
FROM sys.views v
INNER JOIN sys.schemas s ON v.schema_id = s.schema_id
WHERE v.is_ms_shipped = 0
ORDER BY s.name, v.name;

SELECT 
    s.name AS schema_name,
    t.name AS table_name,
    i.name AS index_name,
    i.type_desc,
    i.is_unique,
    i.is_primary_key
FROM sys.indexes i
INNER JOIN sys.tables t ON i.object_id = t.object_id
INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
WHERE i.is_hypothetical = 0
ORDER BY s.name, t.name, i.index_id;

SELECT 
    s.name AS schema_name,
    t.name AS table_name,
    p.partition_number,
    p.rows AS row_count
FROM sys.partitions p
INNER JOIN sys.tables t ON p.object_id = t.object_id
INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
WHERE p.index_id IN (0, 1)
ORDER BY s.name, t.name, p.partition_number;

SELECT 
    s.name AS schema_name,
    t.name AS table_name,
    c.name AS column_name,
    dc.name AS constraint_name,
    dc.definition
FROM sys.default_constraints dc
INNER JOIN sys.tables t ON dc.parent_object_id = t.object_id
INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
INNER JOIN sys.columns c ON dc.parent_object_id = c.object_id AND dc.parent_column_id = c.column_id
ORDER BY s.name, t.name, c.column_id;

SELECT 
    s.name AS schema_name,
    t.name AS table_name,
    c.name AS column_name,
    cc.name AS constraint_name,
    cc.definition
FROM sys.check_constraints cc
INNER JOIN sys.tables t ON cc.parent_object_id = t.object_id
INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
INNER JOIN sys.columns c ON cc.parent_object_id = c.object_id AND cc.parent_column_id = c.column_id
ORDER BY s.name, t.name, c.column_id;

SELECT 
    s.name AS schema_name,
    t.name AS table_name,
    c.name AS column_name,
    kc.name AS constraint_name,
    kc.type_desc
FROM sys.key_constraints kc
INNER JOIN sys.tables t ON kc.parent_object_id = t.object_id
INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
INNER JOIN sys.index_columns ic ON kc.unique_index_id = ic.index_id AND kc.parent_object_id = ic.object_id
INNER JOIN sys.columns c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
ORDER BY s.name, t.name, c.column_id;

SELECT 
    s.name AS schema_name,
    t.name AS table_name,
    c.name AS column_name,
    fk.name AS foreign_key_name,
    rs.name AS referenced_schema,
    rt.name AS referenced_table,
    rc.name AS referenced_column
FROM sys.foreign_keys fk
INNER JOIN sys.foreign_key_columns fkc ON fk.object_id = fkc.constraint_object_id
INNER JOIN sys.tables t ON fkc.parent_object_id = t.object_id
INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
INNER JOIN sys.columns c ON fkc.parent_object_id = c.object_id AND fkc.parent_column_id = c.column_id
INNER JOIN sys.tables rt ON fkc.referenced_object_id = rt.object_id
INNER JOIN sys.schemas rs ON rt.schema_id = rs.schema_id
INNER JOIN sys.columns rc ON fkc.referenced_object_id = rc.object_id AND fkc.referenced_column_id = rc.column_id
ORDER BY s.name, t.name, fk.name;

SELECT 
    s.name AS schema_name,
    t.name AS table_name,
    c.name AS column_name,
    st.name AS stats_name,
    st.filter_definition
FROM sys.stats st
INNER JOIN sys.stats_columns sc ON st.object_id = sc.object_id AND st.stats_id = sc.stats_id
INNER JOIN sys.tables t ON st.object_id = t.object_id
INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
INNER JOIN sys.columns c ON sc.object_id = c.object_id AND sc.column_id = c.column_id
WHERE st.is_incremental = 0
ORDER BY s.name, t.name, st.name;

SELECT 
    s.name AS schema_name,
    t.name AS table_name,
    c.name AS column_name,
    cc.name AS computed_column_name,
    cc.definition
FROM sys.computed_columns cc
INNER JOIN sys.tables t ON cc.object_id = t.object_id
INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
INNER JOIN sys.columns c ON cc.object_id = c.object_id AND cc.column_id = c.column_id
ORDER BY s.name, t.name, cc.name;

SELECT 
    s.name AS schema_name,
    t.name AS table_name,
    c.name AS column_name,
    se.name AS sequence_name
FROM sys.sequences se
INNER JOIN sys.tables t ON se.object_id = t.object_id
INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
INNER JOIN sys.columns c ON se.object_id = c.object_id AND se.column_id = c.column_id
ORDER BY s.name, t.name, c.column_id;

SELECT 
    s.name AS schema_name,
    t.name AS table_name,
    c.name AS column_name,
    cc.name AS constraint_name,
    cc.definition
FROM sys.check_constraints cc
INNER JOIN sys.tables t ON cc.parent_object_id = t.object_id
INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
INNER JOIN sys.columns c ON cc.parent_object_id = c.object_id AND cc.parent_column_id = c.column_id
WHERE cc.definition LIKE '%customer_id%' OR cc.definition LIKE '%full_name%' OR cc.definition LIKE '%email%' OR cc.definition LIKE '%phone%'
ORDER BY s.name, t.name, cc.name;

SELECT 
    s.name AS schema_name,
    t.name AS table_name,
    c.name AS column_name,
    ix.name AS index_name,
    ix.type_desc,
    ix.filter_definition
FROM sys.indexes ix
INNER JOIN sys.index_columns ixc ON ix.object_id = ixc.object_id AND ix.index_id = ixc.index_id
INNER JOIN sys.tables t ON ix.object_id = t.object_id
INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
INNER JOIN sys.columns c ON ixc.object_id = c.object_id AND ixc.column_id = c.column_id
WHERE ix.is_hypothetical = 0
ORDER BY s.name, t.name, ix.name, ixc.key_ordinal;
