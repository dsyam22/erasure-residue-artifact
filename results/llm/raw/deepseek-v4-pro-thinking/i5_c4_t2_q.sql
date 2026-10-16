SELECT DB_NAME() AS database_name;

SELECT 'dbo.customer subject rows' AS check_name;
SELECT * FROM dbo.customer
WHERE customer_id = 42
   OR full_name = N'Subject_0000042'
   OR email = N'subject42@example.invalid'
   OR phone = N'+1-555-0000042';

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
    c.definition AS column_definition
FROM sys.tables t
JOIN sys.schemas s ON t.schema_id = s.schema_id
JOIN sys.columns c ON c.object_id = t.object_id
JOIN sys.types ty ON c.user_type_id = ty.user_type_id
ORDER BY s.name, t.name, c.column_id;

SELECT 
    s.name AS schema_name,
    t.name AS table_name,
    SUM(p.rows) AS row_count
FROM sys.tables t
JOIN sys.schemas s ON t.schema_id = s.schema_id
JOIN sys.partitions p ON t.object_id = p.object_id
WHERE p.index_id IN (0, 1)
GROUP BY s.name, t.name
ORDER BY s.name, t.name;

SELECT 
    s.name AS schema_name,
    v.name AS view_name,
    m.definition
FROM sys.views v
JOIN sys.schemas s ON s.schema_id = v.schema_id
LEFT JOIN sys.sql_modules m ON m.object_id = v.object_id
ORDER BY s.name, v.name;

SELECT 
    s.name AS schema_name,
    syn.name AS synonym_name,
    syn.base_object_name
FROM sys.synonyms syn
JOIN sys.schemas s ON syn.schema_id = s.schema_id
ORDER BY s.name, syn.name;

SELECT 
    s.name AS schema_name,
    o.name AS object_name,
    o.type_desc,
    m.definition
FROM sys.sql_modules m
JOIN sys.objects o ON m.object_id = o.object_id
JOIN sys.schemas s ON o.schema_id = s.schema_id
WHERE o.type IN ('P','FN','IF','TF','TR')
ORDER BY o.type_desc, s.name, o.name;

SELECT 
    ps.name AS parent_schema,
    pt.name AS parent_table,
    fk.name AS foreign_key_name,
    fk.is_disabled,
    rs.name AS referenced_schema,
    rt.name AS referenced_table
FROM sys.foreign_keys fk
JOIN sys.tables pt ON fk.parent_object_id = pt.object_id
JOIN sys.schemas ps ON pt.schema_id = ps.schema_id
JOIN sys.tables rt ON fk.referenced_object_id = rt.object_id
JOIN sys.schemas rs ON rt.schema_id = rs.schema_id
ORDER BY ps.name, pt.name, fk.name;

SELECT 
    s.name AS schema_name,
    o.name AS parent_name,
    o.type_desc AS parent_type,
    tr.name AS trigger_name,
    tr.is_disabled,
    m.definition
FROM sys.triggers tr
JOIN sys.objects o ON tr.parent_id = o.object_id
JOIN sys.schemas s ON o.schema_id = s.schema_id
LEFT JOIN sys.sql_modules m ON tr.object_id = m.object_id
ORDER BY s.name, o.name, tr.name;
