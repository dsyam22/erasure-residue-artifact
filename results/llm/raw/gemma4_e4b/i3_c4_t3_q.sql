SELECT
    t.name AS TableName,
    c.name AS ColumnName,
    ty.name AS DataType,
    c.max_length AS MaxLengthBytes,
    c.is_nullable AS IsNullable
FROM
    sys.tables t
JOIN
    sys.columns c ON t.object_id = c.object_id
JOIN
    sys.types ty ON c.system_type_id = ty.system_type_id AND c.user_type_id = ty.user_type_id
WHERE
    t.schema_name IN ('dbo')
    AND t.name IN ('customer', 'member')
ORDER BY
    TableName, ColumnName;
