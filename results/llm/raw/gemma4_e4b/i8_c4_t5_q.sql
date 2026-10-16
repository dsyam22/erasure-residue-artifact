-- 1. Inspect the structure of the primary table to confirm column definitions and data types.
SELECT
    COLUMN_NAME,
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH,
    IS_NULLABLE
FROM
    INFORMATION_SCHEMA.COLUMNS
WHERE
    TABLE_SCHEMA = 'dbo' AND TABLE_NAME = 'customer'
ORDER BY
    ORDINAL_POSITION;

-- 2. List all user-defined tables in the database to ensure no other PII storage locations exist (e.g., audit logs, staging tables).
SELECT
    TABLE_SCHEMA,
    TABLE_NAME
FROM
    INFORMATION_SCHEMA.TABLES
WHERE
    TABLE_TYPE = 'BASE TABLE'
ORDER BY
    TABLE_NAME;

-- 3. Check for any foreign key constraints or dependencies on the customer table that might imply related data storage (e.g., orders, profiles).
SELECT
    fk.CONSTRAINT_NAME,
    OBJECT_NAME(fk.parent_object_id) AS ChildTable,
    COL_NAME(fkc.parent_object_id, fkc.parent_column_id) AS ChildColumn,
    OBJECT_NAME(fk.referenced_object_id) AS ParentTable,
    COL_NAME(fkc.referenced_object_id, fkc.referenced_column_id) AS ParentColumn
FROM
    sys.foreign_keys AS fk
JOIN
    sys_objects AS parent_obj ON fk.parent_object_id = parent_obj.object_id
JOIN
    sys_columns AS fkc ON fkc.object_id = fk.parent_object_id AND fkc.column_id = fkc.parent_column_id
WHERE
    OBJECT_NAME(fk.parent_object_id) = 'customer';
