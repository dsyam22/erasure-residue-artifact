SELECT 
    t.name AS table_name,
    c.name AS column_name,
    TYPE_NAME(c.user_type_id) AS data_type,
    c.max_length,
    c.is_nullable
FROM sys.columns c
INNER JOIN sys.tables t ON c.object_id = t.object_id
WHERE t.name IN ('customer', 'member')
ORDER BY t.name, c.column_id;

SELECT 
    i.name AS index_name,
    t.name AS table_name,
    i.type_desc,
    i.is_unique,
    i.is_primary_key,
    i.filter_definition
FROM sys.indexes i
INNER JOIN sys.tables t ON i.object_id = t.object_id
WHERE t.name IN ('customer', 'member')
ORDER BY t.name, i.index_id;

SELECT 
    fk.name AS foreign_key_name,
    parent_t.name AS parent_table,
    child_t.name AS child_table,
    fk.is_disabled,
    fk.delete_referential_action_desc
FROM sys.foreign_keys fk
INNER JOIN sys.tables parent_t ON fk.referenced_object_id = parent_t.object_id
INNER JOIN sys.tables child_t ON fk.parent_object_id = child_t.object_id
WHERE parent_t.name IN ('customer', 'member') OR child_t.name IN ('customer', 'member');
