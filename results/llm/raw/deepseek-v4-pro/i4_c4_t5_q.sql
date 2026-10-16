SELECT 
    t.name AS table_name,
    c.name AS column_name,
    ty.name AS data_type,
    c.max_length,
    c.is_nullable
FROM sys.tables t
INNER JOIN sys.columns c ON t.object_id = c.object_id
INNER JOIN sys.types ty ON c.user_type_id = ty.user_type_id
WHERE t.name IN ('customer', 'member')
ORDER BY t.name, c.column_id;

SELECT 
    i.name AS index_name,
    i.type_desc AS index_type,
    i.is_unique,
    i.filter_definition,
    STRING_AGG(c.name, ', ') WITHIN GROUP (ORDER BY ic.key_ordinal) AS index_columns
FROM sys.indexes i
INNER JOIN sys.index_columns ic ON i.object_id = ic.object_id AND i.index_id = ic.index_id
INNER JOIN sys.columns c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
WHERE i.object_id IN (OBJECT_ID('dbo.customer'), OBJECT_ID('dbo.member'))
GROUP BY i.name, i.type_desc, i.is_unique, i.filter_definition;

SELECT 
    fk.name AS foreign_key_name,
    OBJECT_NAME(fk.parent_object_id) AS referencing_table,
    OBJECT_NAME(fk.referenced_object_id) AS referenced_table
FROM sys.foreign_keys fk
WHERE fk.parent_object_id IN (OBJECT_ID('dbo.customer'), OBJECT_ID('dbo.member'))
   OR fk.referenced_object_id IN (OBJECT_ID('dbo.customer'), OBJECT_ID('dbo.member'));

SELECT 
    OBJECT_NAME(m.object_id) AS table_name,
    m.definition
FROM sys.sql_modules m
WHERE m.object_id IN (OBJECT_ID('dbo.customer'), OBJECT_ID('dbo.member'));

SELECT 
    OBJECT_NAME(s.object_id) AS object_name,
    s.type_desc,
    s.definition
FROM sys.sql_modules s
WHERE s.definition LIKE '%customer%' OR s.definition LIKE '%member%';
