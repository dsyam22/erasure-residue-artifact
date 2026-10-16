SELECT 
    t.name AS TableName,
    c.name AS ColumnName,
    ty.name AS DataType,
    is_nullable = CAST(CASE WHEN c.is_nullable = 1 THEN 'Yes' ELSE 'No' END AS nvarchar) AS Nullable,
    -- Check if the column name suggests PII (for quick manual review)
    CASE 
        WHEN LOWER(c.name) LIKE '%name%' OR LOWER(c.name) LIKE '%email%' OR LOWER(c.name) LIKE '%phone%' OR LOWER(c.name) LIKE '%id%' THEN 'Potential PII/Identifier'
        ELSE 'Standard Data'
    END AS Potential_PII_Flag
FROM 
    sys.tables t
INNER JOIN 
    sys.columns c ON t.object_id = c.object_id
INNER JOIN 
    sys.types ty ON c.system_type_id = ty.system_type_id AND c.user_type_id = ty.user_type_id
WHERE 
    t.schema_id = SCHEMA_ID('dbo') -- Focus on the default schema
ORDER BY 
    TableName, ColumnName;
