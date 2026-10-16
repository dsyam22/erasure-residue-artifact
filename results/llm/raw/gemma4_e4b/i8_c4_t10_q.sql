SELECT
    s.name AS schema_name,
    t.name AS table_name,
    c.name AS column_name,
    ty.name AS data_type,
    CASE
        WHEN ty.name IN ('nvarchar', 'varchar', 'char') THEN 'Potential Text/PII'
        WHEN ty.name IN ('int', 'bigint') THEN 'Identifier'
        ELSE 'Other'
    END AS potential_data_category
FROM 
    sys.tables t
JOIN 
    sys.schemas s ON t.schema_id = s.schema_id
JOIN 
    sys.columns c ON t.object_id = c.object_id
JOIN 
    sys.types ty ON c.system_type_id = ty.system_type_id AND c.user_type_id = ty.user_type_id
WHERE 
    t.is_ms_shipped = 0 -- Exclude system tables
ORDER BY
    schema_name, table_name, column_name;
