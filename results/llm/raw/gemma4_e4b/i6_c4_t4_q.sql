-- Check the schema of the relevant table to confirm the column set after dropping the phone number.
SELECT 
    c.name AS column_name, 
    t.type_name(c.user_type_id) AS data_type, 
    c.max_length AS max_size
FROM 
    sys.columns c
JOIN 
    sys.objects o ON c.object_id = o.object_id
JOIN 
    sys.types t ON t.user_type_id = c.user_type_id
WHERE 
    o.name = 'customer' AND SCHEMA_NAME(o.schema_id) = 'dbo';

-- Verify the content of customer_id 42 in dbo.customer to ensure no phone number data persists.
SELECT 
    customer_id, 
    full_name, 
    email
FROM 
    dbo.customer
WHERE 
    customer_id = 42;
