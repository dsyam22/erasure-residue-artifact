SELECT 
    t.name AS TableName,
    c.name AS ColumnName,
    ty.name AS DataType,
    is_nullable,
    CASE WHEN tc.is_primary_key = 1 THEN 'PK' ELSE '' END +
    CASE WHEN fk.constraint_name IS NOT NULL THEN ' (FK to: ' + OBJECT_NAME(fk.parent_object_id) + ')' ELSE '' END AS Constraints
FROM 
    sys.tables t
INNER JOIN 
    sys.columns c ON t.object_id = c.object_id
INNER JOIN 
    sys.types ty ON c.system_type_id = ty.system_type_id AND c.user_type_id = ty.user_type_id
LEFT JOIN 
    sys.foreign_keys fk ON t.object_id = fk.referenced_object_id
LEFT JOIN 
    sys.key_constraints kc ON t.object_id = kc.parent_object_id AND kc.type = 'PK'
CROSS APPLY 
    (SELECT is_primary_key FROM sys.indexes WHERE object_id = t.object_id) AS tc
WHERE 
    t.is_ms_shipped = 0;

-- Check for foreign key relationships originating from other tables and pointing to dbo.customer (Potential dangling references/dependencies that might not be immediately visible)
SELECT 
    OBJECT_NAME(fk.parent_object_id) AS ReferencingTable,
    COL_NAME(fkc.parent_object_id, fkc.parent_column_id) AS ReferencingColumn,
    'References dbo.customer.' + COL_NAME(fkc.referenced_object_id, fkc.referenced_column_id) AS ReferencedTarget
FROM 
    sys.foreign_keys fk
INNER JOIN 
    sys_foreign_key_columns fkc ON fk.object_id = fkc.constraint_object_id
WHERE 
    fk.referenced_object_id = OBJECT_ID('dbo.customer');

-- Check for triggers that might intercept or log changes to dbo.customer (These could bypass simple DELETEs)
SELECT 
    OBJECT_NAME(trigger_object_id) AS TriggerTable,
    name AS TriggerName,
    OBJECT_DEFINITION(trigger_object_id) AS DefinitionSnippet
FROM 
    sys.objects o
INNER JOIN 
    sys.triggers ON o.object_id = sys.triggers.parent_object_id AND o.type = 'U'
WHERE 
    o.name LIKE '%customer%' OR OBJECT_NAME(trigger_object_id) = 'dbo';
