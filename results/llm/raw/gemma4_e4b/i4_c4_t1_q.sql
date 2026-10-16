-- 1. Inspect Table Structures and Column Data Types for PII fields
SELECT
    t.name AS table_name,
    c.name AS column_name,
    ty.name AS data_type,
    c.max_length,
    CASE WHEN c.is_nullable = 1 THEN 'NULLABLE' ELSE 'NOT NULL' END AS nullability
FROM
    sys.columns c
JOIN
    sys.tables t ON c.table_id = t.object_id
JOIN
    sys.types ty ON c.system_type_id = ty.system_type_id AND c.user_type_id = ty.user_type_id
WHERE
    t.schema_name = 'dbo' AND (c.name IN ('full_name', 'email', 'phone'))

UNION ALL

-- 2. Sample Data Inspection: Retrieve the current state of PII fields from both tables for review.
SELECT
    'Customer Table' AS SourceTable,
    CAST(customer_id AS NVARCHAR) + '|' + full_name + '|' + email + '|' + phone AS RowData
FROM
    dbo.customer
WHERE
    1=1 -- Placeholder condition

UNION ALL

SELECT
    'Member Table' AS SourceTable,
    CAST(member_id AS NVARCHAR) + '|' + full_name + '|' + email + '|' + phone AS RowData
FROM
    dbo.member
WHERE
    1=1;
