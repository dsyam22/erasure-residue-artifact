SET NOCOUNT ON;

SELECT
    s.name AS schema_name,
    t.name AS table_name,
    c.column_id,
    c.name AS column_name,
    TYPE_NAME(c.user_type_id) AS data_type,
    c.max_length,
    c.is_nullable,
    CASE
        WHEN c.name LIKE '%name%' OR c.name LIKE '%mail%' OR c.name LIKE '%phone%'
          OR c.name LIKE '%customer%' OR c.name LIKE '%subject%' OR c.name LIKE '%user%'
          OR c.name LIKE '%addr%' OR c.name LIKE '%note%' OR c.name LIKE '%comment%'
          OR c.name LIKE '%desc%' OR c.name LIKE '%json%' OR c.name LIKE '%payload%'
          OR c.name LIKE '%message%' OR c.name LIKE '%text%'
        THEN 1 ELSE 0
    END AS possible_pii_column,
    p.row_count
FROM sys.schemas AS s
JOIN sys.tables AS t
    ON t.schema_id = s.schema_id
JOIN sys.columns AS c
    ON c.object_id = t.object_id
LEFT JOIN (
    SELECT object_id, SUM(rows) AS row_count
    FROM sys.partitions
    WHERE index_id IN (0, 1)
    GROUP BY object_id
) AS p
    ON p.object_id = t.object_id
ORDER BY s.name, t.name, c.column_id;

-- Also list other object types that may store copies of data (views, procedures, triggers, functions)
SELECT
    SCHEMA_NAME(o.schema_id) AS schema_name,
    o.name AS object_name,
    o.type_desc
FROM sys.objects AS o
WHERE o.type IN ('V', 'P', 'TR', 'FN', 'IF', 'TF')
  AND o.is_ms_shipped = 0
ORDER BY schema_name, object_name;
