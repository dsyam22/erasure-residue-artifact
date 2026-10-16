-- QUERY
SELECT query_text_id, query_sql_text
FROM sys.query_store_query_text
WHERE CHARINDEX(N'Subject_0000042', query_sql_text) > 0
   OR CHARINDEX(N'subject42@example.invalid', query_sql_text) > 0
   OR CHARINDEX(N'+1-555-0000042', query_sql_text) > 0;
