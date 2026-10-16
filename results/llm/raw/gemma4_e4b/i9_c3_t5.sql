DECLARE @CustomerName NVARCHAR(100) = 'Subject_0000042';
DECLARE @Email NVARCHAR(100) = 'subject42@example.invalid';
DECLARE @Phone NVARCHAR(50) = '+1-555-0000042';
DECLARE @CustomerID INT = 42;

-- Variables to hold the count for each object checked
DECLARE @Count_Customer INT;
DECLARE @Count_History INT;

-----------------------------------------------
-- 1. Check Current State (dbo.customer)
-----------------------------------------------
SELECT @Count_Customer = COUNT(*)
FROM dbo.customer c
WHERE c.customer_id = @CustomerID
  AND c.full_name = @CustomerName
  AND c.email = @Email
  AND c.phone = @Phone;

-----------------------------------------------
-- 2. Check Temporal History (dbo.customer_history)
-----------------------------------------------
SELECT @Count_History = COUNT(*)
FROM dbo.customer_history h
WHERE h.customer_id = @CustomerID
  AND h.full_name = @CustomerName
  AND h.email = @Email
  AND h.phone = @Phone;

-- Return the single required result set structure
SELECT 'dbo.customer' AS object_name, @Count_Customer AS rows_found
UNION ALL
SELECT 'dbo.customer_history', @Count_History;
