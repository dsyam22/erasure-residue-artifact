SELECT 
    'Schema Check: dbo.customer columns' AS Inspection_Area, 
    c.COLUMN_NAME, 
    c.DATA_TYPE, 
    c.IS_NULLABLE
FROM 
    INFORMATION_SCHEMA.COLUMNS c
WHERE 
    c.TABLE_SCHEMA = 'dbo' 
AND 
    c.TABLE_NAME = 'customer';

SELECT 
    'Schema Check: dbo.member columns' AS Inspection_Area, 
    c.COLUMN_NAME, 
    c.DATA_TYPE, 
    c.IS_NULLABLE
FROM 
    INFORMATION_SCHEMA.COLUMNS c
WHERE 
    c.TABLE_SCHEMA = 'dbo' 
AND 
    c.TABLE_NAME = 'member';

SELECT 
    'Sample Data Check: dbo.customer (PII columns)' AS Inspection_Area, 
    customer_id, 
    full_name, 
    email, 
    phone
FROM 
    dbo.customer
WHERE 
    customer_id IN (42, 1, 5) -- Checking the target ID and a few others
LIMIT 3;

SELECT 
    'Sample Data Check: dbo.member (PII columns)' AS Inspection_Area, 
    member_id, 
    full_name, 
    email, 
    phone
FROM 
    dbo.member
WHERE 
    member_id IN (42, 1, 5) -- Checking the target ID and a few others
LIMIT 3;
