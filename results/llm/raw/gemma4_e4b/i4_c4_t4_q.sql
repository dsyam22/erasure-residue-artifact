SELECT 
    'dbo.customer' AS TableName, 
    c.COLUMN_NAME, 
    c.DATA_TYPE, 
    c.CHARACTER_MAXIMUM_LENGTH 
FROM sys.columns c
JOIN sys.objects o ON c.object_id = o.object_id
WHERE o.name = 'customer' AND SCHEMA_NAME(o.schema_id) = 'dbo'

UNION ALL

SELECT 
    'dbo.member' AS TableName, 
    c.COLUMN_NAME, 
    c.DATA_TYPE, 
    c.CHARACTER_MAXIMUM_LENGTH 
FROM sys.columns c
JOIN sys.objects o ON c.object_id = o.object_id
WHERE o.name = 'member' AND SCHEMA_NAME(o.schema_id) = 'dbo';

SELECT 
    C.customer_id, 
    C.full_name, 
    C.email, 
    C.phone 
FROM dbo.customer C 
WHERE C.customer_id IN (42); -- Sample check for the target ID

SELECT 
    M.member_id, 
    M.full_name, 
    M.email, 
    M.phone 
FROM dbo.member M 
WHERE M.member_id = 42; -- Sample check for the target ID
