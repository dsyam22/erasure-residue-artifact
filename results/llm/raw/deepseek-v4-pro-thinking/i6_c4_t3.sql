SELECT 'dbo.customer' AS object_name, COUNT(*) AS rows_found
FROM dbo.customer AS c
CROSS APPLY (SELECT c.* FOR XML RAW, TYPE) AS x(xml_data)
WHERE x.xml_data.exist('//@*[contains(string(.), "+1-555-0000042")]') = 1

UNION ALL

SELECT 'cdc.dbo_customer_CT' AS object_name, COUNT(*) AS rows_found
FROM cdc.dbo_customer_CT AS t
CROSS APPLY (SELECT t.* FOR XML RAW, TYPE) AS x(xml_data)
WHERE x.xml_data.exist('//@*[contains(string(.), "+1-555-0000042")]') = 1;
