SELECT
    t.name AS TableName,
    c.name AS ColumnName,
    ty.name AS DataType,
    is_nullable = CAST(CASE WHEN c.is_nullable = 1 THEN 'Yes' ELSE 'No' END AS NVARCHAR) AS IsNullable
FROM
    sys.tables t
INNER JOIN
    sys.columns c ON t.object_id = c.object_id
INNER JOIN
    sys.types ty ON c.system_type_id = ty.system_type_id AND c.user_type_id = ty.user_type_id
WHERE
    t.schema_id = SCHEMA_ID('dbo') -- Only check the dbo schema for simplicity
ORDER BY
    TableName, ColumnName;
