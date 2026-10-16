SELECT
    s.name AS schema_name,
    t.name AS table_name,
    c.name AS column_name,
    ty.name AS data_type,
    c.max_length,
    c.is_nullable
FROM sys.columns c
JOIN sys.tables t ON c.object_id = t.object_id
JOIN sys.schemas s ON t.schema_id = s.schema_id
JOIN sys.types ty ON c.user_type_id = ty.user_type_id
ORDER BY s.name, t.name, c.column_id;

SELECT
    s.name AS schema_name,
    o.name AS object_name,
    o.type_desc,
    m.definition
FROM sys.sql_modules m
JOIN sys.objects o ON m.object_id = o.object_id
JOIN sys.schemas s ON o.schema_id = s.schema_id
ORDER BY s.name, o.name;

SELECT
    s.name AS schema_name,
    t.name AS table_name,
    i.name AS index_name,
    i.type_desc,
    c.name AS column_name
FROM sys.index_columns ic
JOIN sys.indexes i ON ic.object_id = i.object_id AND ic.index_id = i.index_id
JOIN sys.columns c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
JOIN sys.tables t ON i.object_id = t.object_id
JOIN sys.schemas s ON t.schema_id = s.schema_id
ORDER BY s.name, t.name, i.name, ic.key_ordinal;

SELECT
    s.name AS schema_name,
    t.name AS table_name,
    c.name AS column_name,
    c.is_nullable
FROM sys.tables t
JOIN sys.schemas s ON t.schema_id = s.schema_id
JOIN sys.columns c ON c.object_id = t.object_id
WHERE c.name LIKE '%phone%'
   OR c.name LIKE '%tel%'
   OR c.name LIKE '%mobile%'
   OR c.name LIKE '%cell%'
   OR c.name LIKE '%contact%';

SELECT
    OBJECT_SCHEMA_NAME(t.object_id) AS schema_name,
    t.name AS table_name,
    t.is_memory_optimized,
    t.temporal_type_desc,
    t.is_tracked_by_cdc
FROM sys.tables t
ORDER BY schema_name, table_name;

SELECT
    OBJECT_SCHEMA_NAME(fk.parent_object_id) AS child_schema,
    OBJECT_NAME(fk.parent_object_id) AS child_table,
    OBJECT_SCHEMA_NAME(fk.referenced_object_id) AS parent_schema,
    OBJECT_NAME(fk.referenced_object_id) AS parent_table
FROM sys.foreign_keys fk;

SELECT
    OBJECT_SCHEMA_NAME(dc.parent_object_id) AS schema_name,
    OBJECT_NAME(dc.parent_object_id) AS table_name,
    dc.name AS constraint_name,
    col.name AS column_name,
    dc.definition
FROM sys.default_constraints dc
JOIN sys.columns col ON col.object_id = dc.parent_object_id AND col.column_id = dc.parent_column_id;

SELECT
    OBJECT_SCHEMA_NAME(ext.major_id) AS schema_name,
    OBJECT_NAME(ext.major_id) AS object_name,
    ext.minor_id,
    ext.name AS property_name,
    CAST(ext.value AS nvarchar(4000)) AS property_value
FROM sys.extended_properties ext
WHERE ext.class = 1 OR ext.class = 7;
