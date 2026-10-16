-- QUERY
SELECT 'cdc.dbo_customer_CT' AS object_name,
       COUNT(*) AS matching_rows,
       SUM(CASE WHEN customer_id = 42 THEN 1 ELSE 0 END) AS id_42_rows,
       SUM(CASE WHEN full_name = N'Subject_0000042' OR email = N'subject42@example.invalid' OR phone = N'+1-555-0000042' THEN 1 ELSE 0 END) AS pii_match_rows
FROM cdc.dbo_customer_CT;
