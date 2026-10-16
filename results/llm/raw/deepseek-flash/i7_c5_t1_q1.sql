-- QUERY
SELECT TOP 5 * FROM dbo.customer WHERE customer_id = 42;
SELECT TOP 5 * FROM reporting.customer_replica WHERE customer_id = 42;
SELECT name, type_desc FROM sys.objects WHERE type IN ('U','V');
