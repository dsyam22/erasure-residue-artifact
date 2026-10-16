SET NOCOUNT ON;

-- 1. All user tables with temporal, CDC, and change-tracking status
SELECT s.name AS schema_name,
       t.name AS table_name,
       t.temporal_type_desc,
       OBJECT_SCHEMA_NAME(t.history_table_id) AS history_schema,
       OBJECT_NAME(t.history_table_id) AS history_table,
       t.is_tracked_by_cdc,
       CAST(CASE WHEN ct.object_id IS NULL THEN 0 ELSE 1 END AS bit) AS is_change_tracked
FROM sys.tables AS t
JOIN sys.schemas AS s ON s.schema_id = t.schema_id
LEFT JOIN sys.change_tracking_tables AS ct ON ct.object_id = t.object_id
ORDER BY s.name, t.name;

-- 2. Columns anywhere in the database that may hold personal data
SELECT s.name AS schema_name,
       o.name AS object_name,
       o.type_desc,
       c.name AS column_name,
       TYPE_NAME(c.user_type_id) AS data_type,
       c.max_length
FROM sys.columns AS c
JOIN sys.objects AS o ON o.object_id = c.object_id
JOIN sys.schemas AS s ON s.schema_id = o.schema_id
WHERE o.type IN ('U', 'V')
  AND (c.name LIKE '%name%'
       OR c.name LIKE '%email%'
       OR c.name LIKE '%mail%'
       OR c.name LIKE '%phone%'
       OR c.name LIKE '%tel%'
       OR c.name LIKE '%customer%'
       OR c.name LIKE '%member%'
       OR c.name LIKE '%subject%'
       OR c.name LIKE '%person%'
       OR c.name LIKE '%contact%')
ORDER BY s.name, o.name, c.column_id;

-- 3. Foreign keys that reference or are referenced by customer or member
SELECT fk.name AS fk_name,
       OBJECT_SCHEMA_NAME(fk.parent_object_id) + '.' + OBJECT_NAME(fk.parent_object_id) AS child_table,
       OBJECT_SCHEMA_NAME(fk.referenced_object_id) + '.' + OBJECT_NAME(fk.referenced_object_id) AS parent_table,
       fk.delete_referential_action_desc,
       fk.update_referential_action_desc
FROM sys.foreign_keys AS fk
WHERE OBJECT_NAME(fk.parent_object_id) IN ('customer', 'member')
   OR OBJECT_NAME(fk.referenced_object_id) IN ('customer', 'member')
ORDER BY fk.name;

-- 4. Triggers and modules whose definitions mention customer or member
SELECT o.type_desc,
       OBJECT_SCHEMA_NAME(o.object_id) AS schema_name,
       o.name AS object_name,
       OBJECT_NAME(o.parent_object_id) AS parent_table
FROM sys.objects AS o
WHERE o.type IN ('TR', 'P', 'FN', 'IF', 'TF', 'V')
  AND o.object_id IN (
        SELECT m.object_id
        FROM sys.sql_modules AS m
        WHERE m.definition LIKE '%customer%'
           OR m.definition LIKE '%member%')
   OR (o.type = 'TR' AND OBJECT_NAME(o.parent_object_id) IN ('customer', 'member'))
ORDER BY o.type_desc, o.name;

-- 5. Row counts for customer and member, and the temporal history of member_id 42 if it exists
SELECT 'dbo.customer' AS src, COUNT(*) AS row_count FROM dbo.customer
UNION ALL
SELECT 'dbo.member', COUNT(*) FROM dbo.member;

-- 6. Any remaining rows for the subject in the base tables
SELECT 'dbo.customer' AS src, customer_id AS id, full_name, email, phone
FROM dbo.customer
WHERE customer_id = 42
   OR full_name = N'Subject_0000042'
   OR email = N'subject42@example.invalid'
   OR phone = N'+1-555-0000042';

SELECT 'dbo.member' AS src, member_id AS id, full_name, email, phone
FROM dbo.member
WHERE member_id = 42
   OR full_name = N'Subject_0000042'
   OR email = N'subject42@example.invalid'
   OR phone = N'+1-555-0000042';
