SELECT
    t.name AS TableName,
    c.name AS ColumnName,
    ty.name AS DataType,
    is_nullable AS IsNullable,
    c.column_id
FROM
    sys.tables t
INNER JOIN
    sys.columns c ON t.object_id = c.object_id
INNER JOIN
    sys.types ty ON c.system_type_id = ty.system_type_id AND c.user_type_id = ty.user_type_id
WHERE
    t.name IN ('customer', 'member')
ORDER BY
    t.name, c.column_id;

SELECT
    fk.name AS ForeignKeyName,
    OBJECT_NAME(fk.parent_object_id) AS ReferencingTable,
    COL_NAME(fkc.parent_object_id, fkc.parent_column_id) AS ReferencingColumn,
    OBJECT_NAME(fk.referenced_object_id) AS ReferencedTable,
    COL_NAME(fkc.referenced_object_id, fkc.referenced_column_id) AS ReferencedColumn
FROM
    sys.foreign_keys fk
INNER JOIN
    sys_foreign_key_columns fkc ON fk.object_id = fkc.constraint_object_id
WHERE
    OBJECT_NAME(fk.parent_object_id) IN ('customer', 'member') OR OBJECT_NAME(fk.referenced_object_id) IN ('customer', 'member');

SELECT * FROM sys.indexes WHERE object_id IN (OBJECT_ID('dbo.customer'), OBJECT_ID('dbo.member'));
