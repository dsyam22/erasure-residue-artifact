SELECT 
    'dbo.customer' AS TableName, 
    c.COLUMN_NAME, 
    c.DATA_TYPE + '(' + CAST(c.CHARACTER_MAXIMUM_LENGTH AS VARCHAR) + ')' AS DataType,
    c.IS_NULLABLE AS IsNullable
FROM sys.columns c
JOIN sys.tables t ON c.object_id = t.object_id
WHERE t.name = 'customer' AND SCHEMA_NAME(t.schema_id) = 'dbo'

UNION ALL

SELECT 
    'reporting.customer_replica' AS TableName, 
    c.COLUMN_NAME, 
    c.DATA_TYPE + '(' + CAST(c.CHARACTER_MAXIMUM_LENGTH AS VARCHAR) + ')' AS DataType,
    c.IS_NULLABLE AS IsNullable
FROM sys.columns c
JOIN sys.tables t ON c.object_id = t.object_id
WHERE t.name = 'customer_replica' AND SCHEMA_NAME(t.schema_id) = 'reporting';

-- Additionally, check for any records using the subject's ID in both tables (read-only spot check)
SELECT 
    * 
FROM dbo.customer WITH (NOLOCK) WHERE customer_id = 42;

SELECT 
    * 
FROM reporting.customer_replica WITH (NOLOCK) WHERE customer_id = 42;
