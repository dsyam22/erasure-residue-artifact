DECLARE @CustomerName NVARCHAR(100) = 'Subject_0000042';
DECLARE @Email NVARCHAR(100) = 'subject42@example.invalid';
DECLARE @Phone NVARCHAR(50) = '+1-555-0000042';

-- Check the primary customer table for residual PII data
SELECT 
    CAST('dbo.customer' AS NVARCHAR(200)) AS object_name, 
    COUNT(T.customer_id) AS rows_found
FROM dbo.customer T
WHERE 
    T.full_name = @CustomerName 
    AND T.email = @Email 
    AND T.phone = @Phone;

-- Note: No other tables were provided in the schema definitions, and based on the configuration (CDC=0, Non-Temporal), 
-- no system history or change tracking tables can be reliably checked for residual data. 
-- The script checks only the explicitly listed object.
