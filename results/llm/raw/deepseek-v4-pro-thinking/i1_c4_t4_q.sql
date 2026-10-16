SELECT DB_NAME() AS database_name;

SELECT
    o.object_id,
    OBJECT_SCHEMA_NAME(o.object_id) AS schema_name,
    o.name AS object_name,
    o.type,
    o.type_desc,
    o.create_date,
    o.modify_date
FROM sys.objects o
WHERE o.is_ms_shipped = 0
  AND o.type IN ('U','V','P','FN','IF','TF','TR','SO')
ORDER BY o.type, schema_name, object_name;

SELECT
    OBJECT_SCHEMA_NAME(c.object_id) AS schema_name,
    OBJECT_NAME(c.object_id) AS object_name,
    o.type_desc AS object_type,
    c.column_id,
    c.name AS column_name,
    TYPE_NAME(c.user_type_id) AS data_type,
    c.max_length,
    c.precision,
    c.scale,
    c.is_nullable,
    c.is_identity,
    c.is_computed,
    c.collation_name
FROM sys.columns c
JOIN sys.objects o ON o.object_id = c.object_id
WHERE o.is_ms_shipped = 0
  AND o.type IN ('U','V')
ORDER BY schema_name, object_name, c.column_id;

SELECT
    OBJECT_SCHEMA_NAME(p.object_id) AS schema_name,
    OBJECT_NAME(p.object_id) AS object_name,
    o.type_desc AS object_type,
    SUM(p.rows) AS approximate_row_count
FROM sys.partitions p
JOIN sys.objects o ON o.object_id = p.object_id
WHERE o.is_ms_shipped = 0
  AND o.type IN ('U','V')
  AND p.index_id IN (0,1)
GROUP BY p.object_id, o.type_desc, OBJECT_SCHEMA_NAME(p.object_id), OBJECT_NAME(p.object_id)
ORDER BY schema_name, object_name;

SELECT
    fk.name AS fk_name,
    OBJECT_SCHEMA_NAME(fk.parent_object_id) AS referencing_schema,
    OBJECT_NAME(fk.parent_object_id) AS referencing_table,
    STRING_AGG(pc.name, ', ') WITHIN GROUP (ORDER BY fkc.constraint_column_id) AS referencing_columns,
    OBJECT_SCHEMA_NAME(fk.referenced_object_id) AS referenced_schema,
    OBJECT_NAME(fk.referenced_object_id) AS referenced_table,
    STRING_AGG(rc.name, ', ') WITHIN GROUP (ORDER BY fkc.constraint_column_id) AS referenced_columns
FROM sys.foreign_keys fk
JOIN sys.foreign_key_columns fkc
    ON fk.object_id = fkc.constraint_object_id
JOIN sys.columns pc
    ON fkc.parent_object_id = pc.object_id
   AND fkc.parent_column_id = pc.column_id
JOIN sys.columns rc
    ON fkc.referenced_object_id = rc.object_id
   AND fkc.referenced_column_id = rc.column_id
GROUP BY fk.name, fk.parent_object_id, fk.referenced_object_id
ORDER BY referencing_schema, referencing_table, fk_name;

SELECT
    OBJECT_SCHEMA_NAME(i.object_id) AS schema_name,
    OBJECT_NAME(i.object_id) AS object_name,
    i.name AS index_name,
    i.type_desc,
    i.is_unique,
    i.is_primary_key,
    STRING_AGG(c.name, ', ') WITHIN GROUP (ORDER BY ic.key_ordinal) AS key_columns
FROM sys.indexes i
JOIN sys.index_columns ic
    ON i.object_id = ic.object_id
   AND i.index_id = ic.index_id
   AND ic.is_included_column = 0
JOIN sys.columns c
    ON ic.object_id = c.object_id
   AND ic.column_id = c.column_id
WHERE i.type > 0
  AND OBJECTPROPERTY(i.object_id, 'IsMsShipped') = 0
GROUP BY i.object_id, i.name, i.type_desc, i.is_unique, i.is_primary_key
ORDER BY schema_name, object_name, i.name;

SELECT
    OBJECT_SCHEMA_NAME(v.object_id) AS schema_name,
    v.name AS view_name,
    m.definition
FROM sys.views v
LEFT JOIN sys.sql_modules m ON m.object_id = v.object_id
ORDER BY schema_name, view_name;

SELECT
    o.type_desc,
    OBJECT_SCHEMA_NAME(o.object_id) AS schema_name,
    o.name AS object_name,
    m.definition
FROM sys.sql_modules m
JOIN sys.objects o ON o.object_id = m.object_id
WHERE o.is_ms_shipped = 0
  AND o.type IN ('P','FN','IF','TF','TR')
ORDER BY o.type, schema_name, object_name;

SELECT
    OBJECT_SCHEMA_NAME(s.object_id) AS schema_name,
    s.name AS synonym_name,
    s.base_object_name
FROM sys.synonyms s
ORDER BY schema_name, synonym_name;
