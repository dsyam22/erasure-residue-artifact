SELECT 
    t.name AS TableName,
    c.name AS ColumnName,
    ty.name(c.system_type_id) AS DataType,
    CASE WHEN c.is_nullable = 1 THEN 'Nullable' ELSE 'NOT NULL' END AS Nullability,
    CASE WHEN c.name IN ('full_name', 'email', 'phone') THEN 'PII Field' ELSE 'Identifier/Key' END AS DataSensitivity
FROM sys.columns c
JOIN sys.objects t ON c.object_id = t.object_id
JOIN sys.types ty ON c.system_type_id = ty.system_type_id
WHERE t.name IN ('customer', 'member') 
  AND c.name IN ('full_name', 'email', 'phone', 'customer_id', 'member_id')
ORDER BY TableName, DataSensitivity DESC;
