-- Inspecting the schema for the relevant tables to confirm column names, types, and constraints.

SELECT 
    'dbo.customer' AS TableName,
    COLUMN_NAME,
    DATA_TYPE,
    IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'dbo' AND TABLE_NAME = 'customer'
ORDER BY ORDINAL_POSITION;

SELECT 
    'dbo.member' AS TableName,
    COLUMN_NAME,
    DATA_TYPE,
    IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'dbo' AND TABLE_NAME = 'member'
ORDER BY ORDINAL_POSITION;

-- Optional: Check for triggers or stored procedures that might process PII fields when data is modified (though this usually requires deeper system view access).
SELECT 
    OBJECT_NAME(object_id), 
    type_desc, 
    is_disabled
FROM sys.objects
WHERE name LIKE '%customer%' OR name LIKE '%member%';
