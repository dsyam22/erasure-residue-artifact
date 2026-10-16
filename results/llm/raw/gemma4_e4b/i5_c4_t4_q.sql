SELECT
    t.name AS table_name,
    c.name AS column_name,
    ty.name AS data_type,
    CASE 
        WHEN ty.name IN ('nvarchar', 'varchar') AND c.max_length >= 10 THEN 'Potential PII/String'
        ELSE 'General Data Type'
    END AS potential_data_type_category
FROM 
    sys.tables t
INNER JOIN 
    sys.columns c ON t.object_id = c.object_id
INNER JOIN 
    sys.types ty ON c.system_type_id = ty.system_type_id AND c.user_type_id = ty.user_type_id
WHERE 
    t.is_ms_shipped = 0 -- Exclude system tables
ORDER BY 
    table_name, c.column_id;
