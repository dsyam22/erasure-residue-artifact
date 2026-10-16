SELECT 'dbo.customer' AS object_name, CAST(T1.RowCount AS NVARCHAR) AS rows_found
UNION ALL
SELECT 'dbo.customer_history', CAST(T2.RowCount AS NVARCHAR);
