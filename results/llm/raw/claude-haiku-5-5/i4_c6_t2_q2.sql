-- QUERY
SELECT OBJECT_SCHEMA_NAME(c.object_id) AS schema_name,
       OBJECT_NAME(c.object_id) AS table_name,
       c.column_id,
       c.name AS column_name,
       TYPE_NAME(c.user_type_id) AS type_name,
       c.is_nullable
FROM sys.columns c
WHERE c.object_id IN (
        OBJECT_ID(N'cdc.dbo_customer_CT'),
        OBJECT_ID(N'dbo.member_history'),
        OBJECT_ID(N'dbo.member'),
        OBJECT_ID(N'dbo.customer'))
ORDER BY schema_name, table_name, c.column_id;
