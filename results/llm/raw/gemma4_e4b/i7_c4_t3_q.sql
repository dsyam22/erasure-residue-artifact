SELECT 
    t.table_name, 
    c.column_name, 
    c.data_type, 
    c.is_nullable
FROM 
    information_schema.columns c
JOIN 
    information_schema.tables t ON c.table_name = t.table_name
WHERE 
    t.table_schema IN ('dbo', 'reporting') 
    AND t.table_name LIKE '%customer%'
ORDER BY 
    t.table_name, c.ordinal_position;

-- Additionally check for any other tables that might contain PII (e.g., name, email)
SELECT 
    t.table_name, 
    c.column_name, 
    c.data_type 
FROM 
    information_schema.columns c
JOIN 
    information_schema.tables t ON c.table_name = t.table_name
WHERE 
    c.column_name IN ('full_name', 'email', 'phone')
    AND t.table_schema NOT IN ('dbo', 'reporting');
