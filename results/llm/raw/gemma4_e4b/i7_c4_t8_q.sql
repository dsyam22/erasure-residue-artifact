SELECT
    c.TABLE_SCHEMA AS SchemaName,
    c.TABLE_NAME AS TableName,
    c.COLUMN_NAME AS ColumnName,
    c.DATA_TYPE AS DataType,
    c.CHARACTER_MAXIMUM_LENGTH AS MaxLength
FROM
    INFORMATION_SCHEMA.COLUMNS c
WHERE
    (c.TABLE_SCHEMA = 'dbo' AND c.TABLE_NAME = 'customer') OR
    (c.TABLE_SCHEMA = 'reporting' AND c.TABLE_NAME = 'customer_replica')
ORDER BY
    SchemaName, TableName, OrdinalPosition;
