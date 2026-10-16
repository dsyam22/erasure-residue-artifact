SELECT 
    DB_NAME() AS database_name,
    SERVERPROPERTY('ProductVersion') AS product_version,
    SERVERPROPERTY('Edition') AS edition,
    (SELECT d.is_cdc_enabled FROM sys.databases AS d WHERE d.database_id = DB_ID()) AS is_cdc_enabled
;

SELECT 
    s.name AS schema_name,
    t.name AS table_name,
    t.object_id,
    t.temporal_type,
    t.temporal_type_desc,
    hist_s.name AS history_schema_name,
    hist_t.name AS history_table_name,
    t.history_table_id,
    t.is_memory_optimized,
    t.is_external,
    t.is_filetable,
    t.is_node,
    t.is_edge,
    t.durability_desc,
    t.is_tracked_by_cdc,
    ct_t.is_enabled AS change_tracking_table_enabled
FROM sys.tables AS t
JOIN sys.schemas AS s
    ON t.schema_id = s.schema_id
LEFT JOIN sys.tables AS hist_t
    ON t.history_table_id = hist_t.object_id
LEFT JOIN sys.schemas AS hist_s
    ON hist_t.schema_id = hist_s.schema_id
LEFT JOIN sys.change_tracking_tables AS ct_t
    ON ct_t.object_id = t.object_id
WHERE t.is_ms_shipped = 0
ORDER BY s.name, t.name;

SELECT 
    s.name AS schema_name,
    t.name AS table_name,
    c.column_id,
    c.name AS column_name,
    ty.name AS data_type_name,
    c.max_length,
    c.precision,
    c.scale,
    c.is_nullable,
    c.is_identity,
    c.is_computed,
    c.generated_always_type_desc,
    c.is_hidden,
    c.is_sparse,
    c.is_column_set
FROM sys.columns AS c
JOIN sys.tables AS t
    ON c.object_id = t.object_id
JOIN sys.schemas AS s
    ON t.schema_id = s.schema_id
JOIN sys.types AS ty
    ON c.user_type_id = ty.user_type_id
WHERE t.is_ms_shipped = 0
ORDER BY s.name, t.name, c.column_id;

SELECT 
    s.name AS schema_name,
    t.name AS table_name,
    p.name AS period_name,
    p.period_type,
    p.period_type_desc,
    sc_start.name AS period_start_column,
    sc_end.name AS period_end_column
FROM sys.periods AS p
JOIN sys.tables AS t
    ON p.object_id = t.object_id
JOIN sys.schemas AS s
    ON t.schema_id = s.schema_id
JOIN sys.columns AS sc_start
    ON p.object_id = sc_start.object_id
   AND p.start_column_id = sc_start.column_id
JOIN sys.columns AS sc_end
    ON p.object_id = sc_end.object_id
   AND p.end_column_id = sc_end.column_id
WHERE t.is_ms_shipped = 0
ORDER BY s.name, t.name, p.period_type;

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
FROM sys.foreign_keys AS fk
JOIN sys.foreign_key_columns AS fkc
    ON fk.object_id = fkc.constraint_object_id
JOIN sys.tables AS pt
    ON fkc.parent_object_id = pt.object_id
JOIN sys.schemas AS ps
    ON pt.schema_id = ps.schema_id
JOIN sys.columns AS pc
    ON fkc.parent_object_id = pc.object_id
   AND fkc.parent_column_id = pc.column_id
JOIN sys.tables AS rt
    ON fkc.referenced_object_id = rt.object_id
JOIN sys.schemas AS rs
    ON rt.schema_id = rs.schema_id
JOIN sys.columns AS rc
    ON fkc.referenced_object_id = rc.object_id
   AND fkc.referenced_column_id = rc.column_id
ORDER BY fk.name;

SELECT 
    s.name AS schema_name,
    parent.name AS parent_object_name,
    tr.name AS trigger_name,
    tr.is_disabled,
    tr.is_instead_of_trigger
FROM sys.triggers AS tr
JOIN sys.objects AS parent
    ON tr.parent_id = parent.object_id
JOIN sys.schemas AS s
    ON parent.schema_id = s.schema_id
WHERE parent.is_ms_shipped = 0
ORDER BY s.name, parent.name, tr.name;

SELECT 
    s.name AS schema_name,
    o.name AS object_name,
    o.type,
    o.type_desc,
    o.create_date,
    o.modify_date
FROM sys.objects AS o
JOIN sys.schemas AS s
    ON o.schema_id = s.schema_id
WHERE o.is_ms_shipped = 0
  AND o.type IN ('U','V','SN','IF','TF','FN','P')
ORDER BY o.type, s.name, o.name;
