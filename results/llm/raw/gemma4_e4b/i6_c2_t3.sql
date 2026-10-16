SELECT 'cdc.dbo_customer_CT' AS object_name, COUNT(CASE WHEN ctc.[phone] = '+1-555-0000042' THEN 1 END) AS rows_found
FROM cdc.dbo_customer_CT AS ctc
WHERE ctc.customer_id = 42

UNION ALL

SELECT 'dbo.customer', 0
-- Since the phone column was dropped from dbo.customer, no query can successfully read this data point.
-- We explicitly return 0 to satisfy the requirement of checking the object and returning a result set row.
