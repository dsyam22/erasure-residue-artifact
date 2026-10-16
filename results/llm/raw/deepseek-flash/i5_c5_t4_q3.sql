-- QUERY
SELECT 
  (SELECT COUNT(*) FROM sys.tables t WHERE t.name = 'customer') AS customer_tbl,
  (SELECT COUNT(*) FROM sys.tables t WHERE t.name = 'customer_history') AS history_tbl,
  (SELECT COUNT(*) FROM sys.views v WHERE v.name LIKE '%customer%') AS cust_views,
  (SELECT COUNT(*) FROM sys.objects o WHERE o.type IN ('U','V') AND (o.name LIKE '%customer%' OR o.name LIKE '%subject%')) AS related_objects;
