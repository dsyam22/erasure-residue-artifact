SELECT 
    @@SERVERNAME AS server_name,
    DB_NAME() AS database_name,
    SERVERPROPERTY('ProductVersion') AS product_version,
    SERVERPROPERTY('Collation') AS database_collation;

SELECT
    s.name AS schema_name,
    t.name AS table_name,
    t.object_id,
    t.type_desc,
    t.temporal_type,
    t.temporal_type_desc,
    hs.name AS history_schema_name,
    ht.name AS history_table_name,
    t.is_tracked_by_cdc,
    t.is_memory_optimized,
    t.is_external,
    t.is_filetable,
    t.durability_desc,
    t.create_date,
    t.modify_date,
    p.rows AS row_count
FROM sys.tables t
JOIN sys.schemas s ON t.schema_id = s.schema_id
LEFT JOIN sys.tables ht ON t.history_table_id = ht.object_id
LEFT JOIN sys.schemas hs ON ht.schema_id = hs.schema_id
OUTER APPLY (
    SELECT SUM(pr.rows) AS rows
    FROM sys.partitions pr
    WHERE pr.object_id = t.object_id
      AND pr.index_id IN (0,1)
) p
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
    c.collation_name,
    c.is_nullable,
    c.is_identity,
    c.is_computed,
    cc.definition AS computed_definition,
    c.generated_always_type,
    c.generated_always_type_desc,
    c.is_hidden,
    c.is_masked,
    c.encryption_type_desc
FROM sys.columns c
JOIN sys.tables t ON c.object_id = t.object_id
JOIN sys.schemas s ON t.schema_id = s.schema_id
JOIN sys.types ty ON c.user_type_id = ty.user_type_id
LEFT JOIN sys.computed_columns cc 
    ON c.object_id = cc.object_id 
   AND c.column_id = cc.column_id
ORDER BY s.name, t.name, c.column_id;

SELECT
    s.name AS schema_name,
    o.name AS object_name,
    o.type_desc,
    i.name AS index_name,
    i.index_id,
    i.type_desc,
    i.is_primary_key,
    i.is_unique_constraint,
    i.is_unique,
    i.is_disabled,
    i.has_filter,
    i.filter_definition
FROM sys.indexes i
JOIN sys.objects o ON i.object_id = o.object_id
JOIN sys.schemas s ON o.schema_id = s.schema_id
WHERE o.type IN ('U','V')
ORDER BY s.name, o.name, i.index_id;

SELECT
    fk.name AS fk_name,
    ss.name AS parent_schema,
    pt.name AS parent_table,
    pc.name AS parent_column,
    rs.name AS referenced_schema,
    rt.name AS referenced_table,
    rc.name AS referenced_column,
    fk.delete_referential_action_desc,
    fk.update_referential_action_desc
FROM sys.foreign_keys fk
JOIN sys.foreign_key_columns fkc ON fk.object_id = fkc.constraint_object_id
JOIN sys.tables pt ON fkc.parent_object_id = pt.object_id
JOIN sys.schemas ss ON pt.schema_id = ss.schema_id
JOIN sys.columns pc ON fkc.parent_object_id = pc.object_id AND fkc.parent_column_id = pc.column_id
JOIN sys.tables rt ON fkc.referenced_object_id = rt.object_id
JOIN sys.schemas rs ON rt.schema_id = rs.schema_id
JOIN sys.columns rc ON fkc.referenced_object_id = rc.object_id AND fkc.referenced_column_id = rc.column_id
ORDER BY fk.name, fkc.constraint_column_id;

SELECT
    s.name AS schema_name,
    o.name AS object_name,
    o.type_desc,
    m.definition
FROM sys.sql_modules m
JOIN sys.objects o ON m.object_id = o.object_id
JOIN sys.schemas s ON o.schema_id = s.schema_id
WHERE m.definition LIKE '%customer%'
   OR m.definition LIKE '%full_name%'
   OR m.definition LIKE '%email%'
   OR m.definition LIKE '%phone%'
   OR m.definition LIKE '%valid_from%'
   OR m.definition LIKE '%valid_to%'
   OR m.definition LIKE '%subject%'
ORDER BY s.name, o.name;

SELECT
    s.name AS schema_name,
    syn.name AS synonym_name,
    syn.base_object_name
FROM sys.synonyms syn
JOIN sys.schemas s ON syn.schema_id = s.schema_id
ORDER BY s.name, syn.name;

SELECT
    s.name AS schema_name,
    t.name AS table_name,
    i.name AS index_name,
    c.name AS catalog_name,
    i.is_enabled,
    i.change_tracking_state_desc
FROM sys.fulltext_indexes i
JOIN sys.tables t ON i.object_id = t.object_id
JOIN sys.schemas s ON t.schema_id = s.schema_id
JOIN sys.fulltext_catalogs c ON i.fulltext_catalog_id = c.fulltext_catalog_id;

SELECT
    ep.class,
    ep.class_desc,
    s.name AS schema_name,
    o.name AS object_name,
    c.name AS column_name,
    ep.name AS property_name,
    ep.value AS property_value
FROM sys.extended_properties ep
LEFT JOIN sys.objects o ON ep.class IN (1,3,7) AND ep.major_id = o.object_id
LEFT JOIN sys.schemas s ON o.schema_id = s.schema_id
LEFT JOIN sys.columns c ON ep.class = 2 AND ep.major_id = c.object_id AND ep.minor_id = c.column_id
ORDER BY ep.class, ep.major_id, ep.minor_id, ep.name;
