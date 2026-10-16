DECLARE @CustomerData TABLE (
    customer_id INT,
    full_name NVARCHAR(MAX),
    email NVARCHAR(MAX),
    phone NVARCHAR(MAX)
);

INSERT INTO @CustomerData (customer_id, full_name, email, phone) VALUES
(42, 'Subject_0000042', 'subject42@example.invalid', '+1-555-0000042');

SELECT
    'dbo.customer' AS object_name,
    COUNT(C.customer_id) AS rows_found
FROM dbo.customer C
WHERE C.customer_id = (SELECT customer_id FROM @CustomerData);

SELECT
    'cdc.dbo_customer_CT' AS object_name,
    COUNT(T.customer_id) AS rows_found
FROM cdc.dbo_customer_CT T
INNER JOIN @CustomerData CD ON T.customer_id = CD.customer_id;
