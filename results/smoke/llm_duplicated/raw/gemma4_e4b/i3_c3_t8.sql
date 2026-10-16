SELECT 'dbo.customer' AS object_name, COUNT(CASE WHEN T1.customer_id IS NOT NULL THEN 1 END) AS rows_found FROM dbo.customer AS T1 WHERE T1.customer_id = 42
UNION ALL
SELECT 'cdc.dbo_customer_CT', COUNT(CASE WHEN T2.customer_id IS NOT NULL THEN 1 END) FROM cdc.dbo_customer_CT AS T2 WHERE T2.customer_id = 42
UNION ALL
SELECT 'dbo.member', COUNT(CASE WHEN T3.member_id IS NOT NULL THEN 1 END) FROM dbo.member AS T3 WHERE T3.member_id = 42
UNION ALL
SELECT 'dbo.member_history', COUNT(CASE WHEN T4.member_id IS NOT NULL THEN 1 END) FROM dbo.member_history AS T4 WHERE T4.member_id = 42;
