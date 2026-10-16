SELECT 
    t.name AS table_name,
    c.name AS column_name,
    ty.name AS data_type,
    c.max_length,
    c.is_nullable
FROM sys.tables t
JOIN sys.columns c ON t.object_id = c.object_id
JOIN sys.types ty ON c.user_type_id = ty.user_type_id
WHERE t.name IN ('customer', 'member')
ORDER BY t.name, c.column_id;

SELECT 
    OBJECT_NAME(ix.object_id) AS table_name,
    ix.name AS index_name,
    ix.type_desc,
    STRING_AGG(c.name, ', ') WITHIN GROUP (ORDER BY ic.key_ordinal) AS index_columns
FROM sys.indexes ix
JOIN sys.index_columns ic ON ix.object_id = ic.object_id AND ix.index_id = ic.index_id
JOIN sys.columns c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
WHERE ix.object_id IN (OBJECT_ID('dbo.customer'), OBJECT_ID('dbo.member'))
GROUP BY ix.object_id, ix.name, ix.type_desc;

SELECT 
    OBJECT_NAME(fk.parent_object_id) AS referencing_table,
    fk.name AS foreign_key_name,
    OBJECT_NAME(fk.referenced_object_id) AS referenced_table,
    STRING_AGG(pc.name, ', ') AS referencing_columns,
    STRING_AGG(rc.name, ', ') AS referenced_columns
FROM sys.foreign_keys fk
JOIN sys.foreign_key_columns fkc ON fk.object_id = fkc.constraint_object_id
JOIN sys.columns pc ON fkc.parent_object_id = pc.object_id AND fkc.parent_column_id = pc.column_id
JOIN sys.columns rc ON fkc.referenced_object_id = rc.object_id AND fkc.referenced_column_id = rc.column_id
WHERE fk.parent_object_id IN (OBJECT_ID('dbo.customer'), OBJECT_ID('dbo.member'))
   OR fk.referenced_object_id IN (OBJECT_ID('dbo.customer'), OBJECT_ID('dbo.member'))
GROUP BY fk.parent_object_id, fk.name, fk.referenced_object_id;

SELECT 
    OBJECT_NAME(o.object_id) AS table_name,
    i.name AS index_name,
    i.type_desc,
    STRING_AGG(c.name, ', ') AS index_columns
FROM sys.indexes i
JOIN sys.index_columns ic ON i.object_id = ic.object_id AND i.index_id = ic.index_id
JOIN sys.columns c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
JOIN sys.objects o ON i.object_id = o.object_id
WHERE o.name IN ('customer', 'member')
  AND i.type IN (1, 2)  -- clustered and nonclustered
GROUP BY o.object_id, i.name, i.type_desc;
