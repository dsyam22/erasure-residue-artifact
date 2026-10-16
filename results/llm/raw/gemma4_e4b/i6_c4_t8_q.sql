-- Inspect the structure of the target table to confirm the column drop was successful in the reported schema (though this should be redundant if I trust the prompt, it's good practice).
SELECT 
    c.name AS TableName, 
    c.column_name, 
    ty.name AS DataType 
FROM 
    sys.columns c
JOIN 
    sys.types ty ON c.system_type_id = ty.system_type_id AND c.user_type_id = ty.user_type_id
WHERE 
    c.object_id = OBJECT_ID('dbo.customer')
ORDER BY 
    c.column_id;

-- View the actual data to confirm Name and Email are still present for the subject
SELECT 
    customer_id, 
    full_name, 
    email 
FROM 
    dbo.customer 
WHERE 
    customer_id = 42;
