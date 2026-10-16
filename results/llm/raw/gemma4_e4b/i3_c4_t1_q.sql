SELECT
    t.name AS table_name,
    c.name AS column_name,
    ty.name AS data_type,
    c.max_length AS max_length_bytes,
    CASE WHEN is_nullable = 1 THEN 'YES' ELSE 'NO' END AS nullable
FROM
    sys.tables t
JOIN
    sys.columns c ON t.object_id = c.object_id
JOIN
    sys.types ty ON c.system_type_id = ty.system_type_id AND c.user_type_id = ty.user_type_id
WHERE
    t.schema_name IN ('dbo') -- Focus on the dbo schema
ORDER BY
    table_name, column_name;

-- Also checking for any other tables that might store PII or link to customer/member IDs (e.g., audit logs, junction tables)
SELECT
    * FROM sys.objects WHERE type IN ('U') AND name NOT IN ('customer', 'member');
