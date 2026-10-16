SELECT
    s.name AS schema_name,
    t.name AS table_name,
    t.temporal_type_desc,
    t.is_tracked_by_cdc,
    t.object_id,
    c.name AS column_name,
    ty.name AS data_type,
    c.max_length,
    c.is_nullable
FROM sys.tables AS t
JOIN sys.schemas AS s ON s.schema_id = t.schema_id
LEFT JOIN sys.columns AS c ON c.object_id = t.object_id
LEFT JOIN sys.types AS ty ON ty.user_type_id = c.user_type_id
WHERE
    t.is_ms_shipped = 0
    AND (
        c.name LIKE '%cust%'
        OR c.name LIKE '%name%'
        OR c.name LIKE '%mail%'
        OR c.name LIKE '%phone%'
        OR c.name LIKE '%tel%'
        OR c.name LIKE '%person%'
        OR c.name LIKE '%subject%'
        OR c.name LIKE '%user%'
        OR c.name LIKE '%contact%'
        OR c.name LIKE '%addr%'
        OR c.name LIKE '%note%'
        OR c.name LIKE '%json%'
        OR c.name LIKE '%xml%'
        OR ty.name IN ('xml', 'text', 'ntext', 'image', 'sql_variant')
        OR c.name IS NULL
    )
ORDER BY s.name, t.name, c.column_id;

SELECT
    OBJECT_SCHEMA_NAME(fk.parent_object_id) AS referencing_schema,
    OBJECT_NAME(fk.parent_object_id) AS referencing_table,
    OBJECT_SCHEMA_NAME(fk.referenced_object_id) AS referenced_schema,
    OBJECT_NAME(fk.referenced_object_id) AS referenced_table,
    fk.name AS fk_name
FROM sys.foreign_keys AS fk
ORDER BY referencing_schema, referencing_table;

SELECT
    OBJECT_SCHEMA_NAME(ct.object_id) AS schema_name,
    OBJECT_NAME(ct.object_id) AS table_name,
    ct.capture_instance,
    ct.supports_net_changes
FROM cdc.change_tables AS ct;

SELECT
    s.name AS schema_name,
    v.name AS view_name,
    OBJECT_DEFINITION(v.object_id) AS view_definition
FROM sys.views AS v
JOIN sys.schemas AS s ON s.schema_id = v.schema_id
WHERE v.is_ms_shipped = 0;
