SELECT 
    t.name AS TableName,
    c.name AS ColumnName,
    ty.name AS DataType,
    c.max_length / 2 AS MaxLengthBytes, -- Displaying length in characters for nvarchar/nvarchar
    ISNULL(c.is_nullable, 'Yes') AS IsNullable,
    CASE WHEN c.column_id = 1 THEN 'Primary Key Candidate' ELSE '' END AS Notes
FROM 
    sys.tables t
INNER JOIN 
    sys.columns c ON t.object_id = c.object_id
INNER JOIN 
    sys.types ty ON c.system_type_id = ty.system_type_id AND c.user_type_id = ty.user_type_id
WHERE 
    t.schema_id = SCHEMA_ID('dbo') -- Focus on the primary schema
ORDER BY 
    TableName, c.column_id;

-- Additionally checking for any potential triggers or constraints on the customer table
SELECT 
    name AS ConstraintName, 
    type_desc AS ConstraintType, 
    is_disabled AS IsDisabled
FROM 
    sys.objects
WHERE 
    parent_object_id = OBJECT_ID('dbo.customer')
AND 
    type IN ('D', 'F', 'TR'); -- D=Default, F=Foreign Key, TR=Trigger
