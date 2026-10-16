-- 1. Identify all user-defined tables in the database. This helps scope the search area.
SELECT 
    s.name AS schema_name, 
    t.name AS table_name
FROM 
    sys.tables t
JOIN 
    sys.schemas s ON t.schema_id = s.schema_id
WHERE 
    s.name NOT IN ('sys', 'INFORMATION_SCHEMA') -- Exclude system schemas
ORDER BY 
    table_name;

-- 2. Inspect the structure (columns) of all user tables to identify potential PII fields 
-- (e.g., email, phone, name, external IDs). This is crucial for knowing *where* to look next.
SELECT 
    t.name AS table_name, 
    c.name AS column_name, 
    ty.name AS data_type,
    is_nullable
FROM 
    sys.columns c
JOIN 
    sys.tables t ON c.object_id = t.object_id
JOIN 
    sys.types ty ON c.system_type_id = ty.system_type_id AND c.user_type_id = ty.user_type_id
WHERE 
    t.schema_id = SCHEMA_ID('dbo') -- Assuming standard dbo schema usage
ORDER BY 
    table_name, c.column_id;

-- 3. Check for foreign key constraints to understand relationships between tables. 
-- This helps determine if other tables might hold residual references (e.g., an order table referencing a customer ID).
SELECT 
    fk.name AS constraint_name,
    OBJECT_NAME(fk.parent_object_id) AS child_table,
    COL_NAME(fkc.parent_object_id, fkc.parent_column_id) AS child_column,
    OBJECT_NAME(fk.referenced_object_id) AS parent_table,
    COL_NAME(fkc.referenced_object_id, fkc.referenced_column_id) AS parent_column
FROM 
    sys.foreign_keys fk
JOIN 
    sys_foreign_key_columns fkc ON fk.object_id = fkc.constraint_object_id
WHERE 
    OBJECTPROPERTY(fk.parent_object_id, 'IsUserTable') = 1 -- Filter only user-defined relationships
ORDER BY 
    child_table;

-- 4. (Optional but highly recommended) If the database contains historical/audit logging tables, 
-- check for common names that might retain logs or usage data linked to customer IDs.
SELECT * FROM sys.tables WHERE name LIKE '%log%' OR name LIKE '%history%';
