SELECT 
    DB_NAME() AS database_name,
    @@SERVERNAME AS server_name,
    @@VERSION AS sql_version;

SELECT 
    s.name AS schema_name,
    t.name AS table_name,
    t.object_id AS table_object_id,
    t.temporal_type_desc,
    c.column_id,
    c.name AS column_name,
    ty.name AS data_type,
    c.max_length,
    c.precision,
    c.scale,
    c.is_nullable,
    c.is_identity,
    c.is_computed
FROM sys.tables AS t
JOIN sys.schemas AS s ON t.schema_id = s.schema_id
JOIN sys.columns AS c ON c.object_id = t.object_id
JOIN sys.types AS ty ON ty.user_type_id = c.user_type_id
ORDER BY s.name, t.name, c.column_id;

SELECT 
    s.name AS schema_name,
    t.name AS table_name,
    t.object_id AS table_object_id,
    t.temporal_type_desc,
    hist.name AS history_table_name,
    p.row_count AS total_rows
FROM sys.tables AS t
JOIN sys.schemas AS s ON t.schema_id = s.schema_id
LEFT JOIN sys.tables AS hist ON hist.object_id = t.history_table_id
LEFT JOIN (
    SELECT object_id, SUM(rows) AS row_count
    FROM sys.partitions
    WHERE index_id IN (0,1)
    GROUP BY object_id
) AS p ON p.object_id = t.object_id
ORDER BY s.name, t.name;

SELECT 
    fk.name AS foreign_key_name,
    parent_schema.name AS parent_schema,
    parent_table.name AS parent_table,
    parent_col.name AS parent_column,
    ref_schema.name AS referenced_schema,
    ref_table.name AS referenced_table,
    ref_col.name AS referenced_column,
    fk.delete_referential_action_desc,
    fk.update_referential_action_desc
FROM sys.foreign_keys AS fk
JOIN sys.foreign_key_columns AS fkc ON fkc.constraint_object_id = fk.object_id
JOIN sys.tables AS parent_table ON parent_table.object_id = fk.parent_object_id
JOIN sys.schemas AS parent_schema ON parent_schema.schema_id = parent_table.schema_id
JOIN sys.columns AS parent_col ON parent_col.object_id = parent_table.object_id AND parent_col.column_id = fkc.parent_column_id
JOIN sys.tables AS ref_table ON ref_table.object_id = fk.referenced_object_id
JOIN sys.schemas AS ref_schema ON ref_schema.schema_id = ref_table.schema_id
JOIN sys.columns AS ref_col ON ref_col.object_id = ref_table.object_id AND ref_col.column_id = fkc.referenced_column_id
ORDER BY fk.name, fkc.constraint_column_id;

SELECT 
    s.name AS schema_name,
    v.name AS view_name,
    m.definition,
    p.row_count AS indexed_view_row_count
FROM sys.views AS v
JOIN sys.schemas AS s ON v.schema_id = s.schema_id
LEFT JOIN sys.sql_modules AS m ON m.object_id = v.object_id
LEFT JOIN (
    SELECT object_id, SUM(rows) AS row_count
    FROM sys.partitions
    WHERE index_id IN (0,1)
    GROUP BY object_id
) AS p ON p.object_id = v.object_id
ORDER BY s.name, v.name;

SELECT 
    s.name AS trigger_schema,
    tr.name AS trigger_name,
    tr.parent_class_desc,
    OBJECT_SCHEMA_NAME(tr.parent_id) AS parent_schema,
    OBJECT_NAME(tr.parent_id) AS parent_name,
    tr.is_disabled,
    m.definition
FROM sys.triggers AS tr
JOIN sys.schemas AS s ON tr.schema_id = s.schema_id
LEFT JOIN sys.sql_modules AS m ON m.object_id = tr.object_id
WHERE tr.parent_class = 1
ORDER BY parent_schema, parent_name, tr.name;

SELECT 
    s.name AS schema_name,
    o.name AS object_name,
    o.type_desc,
    m.definition
FROM sys.objects AS o
JOIN sys.schemas AS s ON o.schema_id = s.schema_id
JOIN sys.sql_modules AS m ON m.object_id = o.object_id
WHERE o.type IN ('P','FN','IF','TF')
  AND (
        m.definition LIKE '%customer%'
     OR m.definition LIKE '%full_name%'
     OR m.definition LIKE '%email%'
     OR m.definition LIKE '%phone%'
     OR m.definition LIKE '%Subject_0000042%'
     OR m.definition LIKE '%subject42@example.invalid%'
     OR m.definition LIKE '%+1-555-0000042%'
  )
ORDER BY o.type_desc, s.name, o.name;
