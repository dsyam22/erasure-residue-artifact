SELECT 
    'Table Structure Check (PII Columns)' AS Inspection_Area,
    t.table_name,
    c.column_name,
    c.data_type,
    c.is_nullable
FROM 
    INFORMATION_SCHEMA.COLUMNS c
JOIN 
    INFORMATION_SCHEMA.TABLES t ON c.table_name = t.table_name
WHERE 
    t.table_schema = 'dbo'
AND 
    t.table_name IN ('customer', 'member')
AND 
    c.column_name IN ('full_name', 'email', 'phone')

UNION ALL

SELECT 
    'Potential PII Tables Check (System/Schema)' AS Inspection_Area,
    QUOTENAME(s.name) + '.' + QUOTENAME(t.name) AS Table_Name,
    NULL AS Column_Name,
    NULL AS Data_Type,
    'Exists' AS Is_Nullable -- Placeholder for existence check
FROM 
    sys.tables t
JOIN 
    sys.schemas s ON t.schema_id = s.schema_id
WHERE 
    t.name NOT IN ('customer', 'member')
    AND OBJECTPROPERTY(object_id, 'IsUserTable') = 1
ORDER BY 
    Inspection_Area;
