-- Inspecting Database Structure: Tables, Schemas, and Columns 
SELECT 
    t.name AS TableName,
    s.name AS SchemaName,
    c.name AS ColumnName,
    ty.name AS DataType,
    c.max_length AS MaxLength,
    c.is_nullable AS IsNullable
FROM 
    sys.tables t
INNER JOIN 
    sys.schemas s ON t.schema_id = s.schema_id
INNER JOIN 
    sys.columns c ON t.object_id = c.object_id
INNER JOIN 
    sys.types ty ON c.system_type_id = ty.system_type_id
WHERE 
    t.name IN ('customer', 'customer_replica') -- Focus on the known relevant tables
ORDER BY 
    SchemaName, TableName, c.column_id;

-- Additionally, checking for any other views or stored procedures that might reference these tables (potential hidden copies/logic)
SELECT 
    OBJECT_NAME(o.object_id) AS ObjectName,
    t.name AS ReferencedTable
FROM 
    sys.objects o
INNER JOIN 
    sys.sql_expression_dependencies sed ON o.object_id = sed.referencing_id
INNER JOIN 
    sys.tables t ON sed.referenced_entity_name = t.name AND sed.referenced_schema_name = t.schema_name
WHERE 
    o.type IN ('V', 'P') -- Views and Stored Procedures
    AND t.name IN ('customer', 'customer_replica');

-- Checking general database configuration (e.g., replication status, trace flags) for unusual data retention mechanisms
SELECT * FROM sys.databases WHERE name = DB_NAME();
