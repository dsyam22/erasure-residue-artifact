-- 1. Verify the current structure of the customer table to confirm the phone column drop.
SELECT 
    COLUMN_NAME, 
    DATA_TYPE, 
    CHARACTER_MAXIMUM_LENGTH, 
    IS_NULLABLE 
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_NAME = 'customer' AND TABLE_SCHEMA = 'dbo';

-- 2. Inspect the data for the specific subject (ID 42) to ensure only permitted fields remain populated.
SELECT 
    customer_id, 
    full_name, 
    email 
FROM dbo.customer 
WHERE customer_id = 42;

-- 3. Perform a comprehensive search across all relevant character/string columns (in the known table) 
-- to confirm that the specific personal data point ('+1-555-0000042') does not exist anywhere residualy, 
-- even if it was stored in another field like 'full_name' or 'email'.
SELECT TOP 1 * 
FROM dbo.customer c
WHERE 
    c.full_name LIKE '%+1-555-0000042%' OR 
    c.email LIKE '%+1-555-0000042%';
