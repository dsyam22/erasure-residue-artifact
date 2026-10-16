-- Check the current structure of the customer table to ensure only the expected columns remain.
SELECT 
    c.name AS ColumnName, 
    t.type_name(c.user_type_id) AS DataType, 
    c.max_length AS MaxLength
FROM 
    sys.columns c
JOIN 
    sys.types t ON c.system_type_id = t.system_type_id
WHERE 
    c.object_id = OBJECT_ID('dbo.customer')
ORDER BY 
    c.column_id;

-- Verify the current contents of the customer table, specifically for customer_id 42, 
-- to confirm that no phone number column/data point is present.
SELECT 
    customer_id, 
    full_name, 
    email
FROM 
    dbo.customer
WHERE 
    customer_id = 42;

-- Check for any triggers or default constraints on the dbo.customer table that might interact with sensitive data.
SELECT 
    T.name AS TriggerName, 
    OBJECT_SCHEMA_NAME(T.object_id) AS SchemaName, 
    OBJECT_NAME(T.object_id) AS TableName, 
    T.is_disabled
FROM 
    sys.triggers T
JOIN 
    sys.objects O ON T.object_id = O.object_id
WHERE 
    O.name = 'customer' AND OBJECT_SCHEMA_NAME(O.object_id) = 'dbo';

-- Check for any indexes on the table that might be storing sensitive data (though unlikely given the schema change).
SELECT 
    i.name AS IndexName, 
    OBJECT_NAME(i.object_id) AS TableName, 
    COL_NAME(ic.object_id, ic.column_id) AS ColumnName
FROM 
    sys.indexes i
JOIN 
    sys.index_columns ic ON i.object_id = ic.object_id AND i.index_id = ic.index_id
WHERE 
    i.object_id = OBJECT_ID('dbo.customer')
ORDER BY 
    TableName, IndexName, ic.key_ordinal;
