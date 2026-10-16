-- Check the schema of the customer table to confirm the phone column is gone
SELECT 
    c.name AS column_name, 
    t.name AS data_type 
FROM 
    sys.columns c
JOIN 
    sys.types t ON c.system_type_id = t.system_type_id AND c.user_type_id = t.user_type_id
WHERE 
    c.object_id = OBJECT_ID('dbo.customer')
ORDER BY 
    c.column_id;

-- Inspect the actual data for the subject (customer_id 42) in all existing columns
SELECT 
    customer_id, 
    full_name, 
    email 
FROM 
    dbo.customer 
WHERE 
    customer_id = 42;
