SELECT 'Database Info' AS section;
SELECT DB_NAME() AS database_name, @@SERVERNAME AS server_name, @@VERSION AS sql_version;

SELECT 'Tables and Row Counts' AS section;
SELECT s.name AS schema_name, t.name AS table_name, SUM(p.rows) AS row_count, t.create_date, t.modify_date
FROM sys.tables t
JOIN sys.schemas s ON t.schema_id = s.schema_id
LEFT JOIN sys.partitions p ON t.object_id = p.object_id AND p.index_id IN (0,1)
GROUP BY s.name, t.name, t.create_date, t.modify_date
ORDER BY s.name, t.name;

SELECT 'Columns' AS section;
SELECT s.name AS schema_name, t.name AS table_name, c.name AS column_name,
       TYPE_NAME(c.user_type_id) AS data_type, c.max_length, c.precision, c.scale,
       c.is_nullable, c.is_identity, c.is_computed
FROM sys.columns c
JOIN sys.tables t ON c.object_id = t.object_id
JOIN sys.schemas s ON t.schema_id = s.schema_id
ORDER BY s.name, t.name, c.column_id;

SELECT 'Foreign Keys' AS section;
SELECT fk.name AS fk_name,
       ss.name AS fk_schema, st.name AS fk_table,
       ts.name AS pk_schema, tt.name AS pk_table
FROM sys.foreign_keys fk
JOIN sys.tables st ON fk.parent_object_id = st.object_id
JOIN sys.schemas ss ON st.schema_id = ss.schema_id
JOIN sys.tables tt ON fk.referenced_object_id = tt.object_id
JOIN sys.schemas ts ON tt.schema_id = ts.schema_id
ORDER BY ss.name, st.name, fk.name;

SELECT 'Other User Objects' AS section;
SELECT s.name AS schema_name, o.name AS object_name, o.type_desc, o.create_date, o.modify_date
FROM sys.objects o
JOIN sys.schemas s ON o.schema_id = s.schema_id
WHERE o.is_ms_shipped = 0
  AND o.type NOT IN ('U') -- exclude user tables; already listed above
ORDER BY o.type_desc, s.name, o.name;

SELECT 'Module Definitions' AS section;
SELECT s.name AS schema_name, o.name AS object_name, o.type_desc, m.definition
FROM sys.sql_modules m
JOIN sys.objects o ON m.object_id = o.object_id
JOIN sys.schemas s ON o.schema_id = s.schema_id
WHERE o.is_ms_shipped = 0
ORDER BY o.type_desc, s.name, o.name;
