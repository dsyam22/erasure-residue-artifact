-- Inspecting the structure of the relevant tables
SELECT 
    c.name AS table_name, 
    c.column_name, 
    ty.name AS data_type, 
    c.max_length, 
    c.is_nullable
FROM sys.columns c
JOIN sys.types ty ON c.system_type_id = ty.system_type_id
WHERE OBJECT_ID(c.object_id) IN (OBJECT_ID('dbo.customer'), OBJECT_ID('dbo.member'))
ORDER BY table_name, c.column_name;

-- Inspecting the current data in dbo.customer for records related to customer 42 and general review
SELECT 
    'Customer' AS source_table,
    customer_id,
    full_name,
    email,
    phone
FROM dbo.customer
WHERE customer_id = 42 OR full_name LIKE '%Subject%' -- Check the specific record and any potentially non-anonymized records
UNION ALL

-- Inspecting the current data in dbo.member for records related to member 42 and general review
SELECT 
    'Member' AS source_table,
    member_id,
    full_name,
    email,
    phone
FROM dbo.member
WHERE member_id = 42 OR full_name LIKE '%Subject%'; -- Check the specific record and any potentially non-anonymized records
