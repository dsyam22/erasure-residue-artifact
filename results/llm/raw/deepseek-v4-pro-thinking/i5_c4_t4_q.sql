SELECT 
    DB_NAME() AS database_name,
    SERVERPROPERTY('ServerName') AS server_name,
    SERVERPROPERTY('ProductVersion') AS product_version,
    SERVERPROPERTY('Edition') AS edition;

SELECT 
    s.name AS schema_name,
    t.name AS table_name,
    t.type_desc,
    t.temporal_type,
    t.temporal_type_desc,
    ht_s.name AS history_schema_name,
    ht.name AS history_table_name,
    p.rows AS row_count
FROM sys.tables t
JOIN sys.schemas s ON t.schema_id = s.schema_id
LEFT JOIN sys.tables ht ON t.history_table_id = ht.object_id
LEFT JOIN sys.schemas ht_s ON ht.schema_id = ht_s.schema_id
LEFT JOIN sys.partitions p ON t.object_id = p.object_id AND p.index_id IN (0,1)
WHERE t.is_ms_shipped = 0
ORDER BY s.name, t.name;

SELECT 
    s.name AS schema_name,
    t.name AS table_name,
    c.column_id,
    c.name AS column_name,
    ty.name AS type_name,
    c.max_length,
    c.precision,
    c.scale,
    c.collation_name,
    c.is_nullable,
    c.is_identity,
    c.is_computed,
    c.generated_always_type,
    c.generated_always_type_desc,
    cc.definition AS computed_column_definition
FROM sys.columns c
JOIN sys.tables t ON c.object_id = t.object_id
JOIN sys.schemas s ON t.schema_id = s.schema_id
JOIN sys.types ty ON c.user_type_id = ty.user_type_id
LEFT JOIN sys.computed_columns cc ON c.object_id = cc.object_id AND c.column_id = cc.column_id
WHERE t.is_ms_shipped = 0
ORDER BY s.name, t.name, c.column_id;

SELECT 
    s.name AS schema_name,
    o.name AS object_name,
    o.type,
    o.type_desc,
    m.definition
FROM sys.objects o
JOIN sys.schemas s ON o.schema_id = s.schema_id
LEFT JOIN sys.sql_modules m ON o.object_id = m.object_id
WHERE o.is_ms_shipped = 0
  AND o.type IN ('V','P','FN','IF','TF','TR')
ORDER BY o.type_desc, s.name, o.name;

SELECT 
    s.name AS schema_name,
    t.name AS table_name,
    i.name AS index_name,
    i.type_desc,
    i.is_unique,
    i.filter_definition,
    STUFF((
        SELECT ',' + col.name 
        FROM sys.index_columns ic
        JOIN sys.columns col ON ic.object_id = col.object_id AND ic.column_id = col.column_id
        WHERE ic.object_id = i.object_id AND ic.index_id = i.index_id
        ORDER BY ic.key_ordinal
        FOR XML PATH('')
    ), 1, 1, '') AS index_columns
FROM sys.indexes i
JOIN sys.tables t ON i.object_id = t.object_id
JOIN sys.schemas s ON t.schema_id = s.schema_id
WHERE t.is_ms_shipped = 0
  AND i.name IS NOT NULL
ORDER BY s.name, t.name, i.index_id;

SELECT 
    s.name AS schema_name,
    syn.name AS synonym_name,
    base_server_name,
    base_database_name,
    base_schema_name,
    base_object_name
FROM sys.synonyms syn
JOIN sys.schemas s ON syn.schema_id = s.schema_id
ORDER BY s.name, syn.name;

SELECT 
    s.name AS schema_name,
    t.name AS table_name,
    c.name AS column_name,
    fk.name AS foreign_key_name,
    ref_s.name AS referenced_schema_name,
    ref_t.name AS referenced_table_name,
    ref_c.name AS referenced_column_name
FROM sys.foreign_key_columns fkc
JOIN sys.foreign_keys fk ON fkc.constraint_object_id = fk.object_id
JOIN sys.tables t ON fk.parent_object_id = t.object_id
JOIN sys.schemas s ON t.schema_id = s.schema_id
JOIN sys.columns c ON fkc.parent_object_id = c.object_id AND fkc.parent_column_id = c.column_id
JOIN sys.tables ref_t ON fkc.referenced_object_id = ref_t.object_id
JOIN sys.schemas ref_s ON ref_t.schema_id = ref_s.schema_id
JOIN sys.columns ref_c ON fkc.referenced_object_id = ref_c.object_id AND fkc.referenced_column_id = ref_c.column_id
WHERE t.is_ms_shipped = 0
ORDER BY s.name, t.name, c.name;
