SELECT
    t.name AS TableName,
    c.name AS ColumnName,
    ty.name AS DataType,
    is_nullable,
    -- Check if this column name matches common PII identifiers
    CASE
        WHEN LOWER(c.name) LIKE '%name%' OR LOWER(c.name) = 'full_name' THEN 'Potential Name Field'
        WHEN LOWER(c.name) LIKE '%email%' OR LOWER(c.name) = 'email' THEN 'Potential Email Field'
        WHEN LOWER(c.name) LIKE '%phone%' OR LOWER(c.name) = 'phone' THEN 'Potential Phone Field'
        ELSE NULL
    END AS PII_Indicator
FROM 
    sys.tables t
INNER JOIN 
    sys.columns c ON t.object_id = c.object_id
INNER JOIN 
    sys.types ty ON c.system_type_id = ty.system_type_id AND c.user_type_id = ty.user_type_id
WHERE
    t.schema_name = 'dbo'
ORDER BY 
    TableName, ColumnName;
