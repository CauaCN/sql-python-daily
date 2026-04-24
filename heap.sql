DECLARE @command NVARCHAR(MAX);
DECLARE @Results TABLE (
    Banco NVARCHAR(128),
    Esquema NVARCHAR(128),
    Tabela NVARCHAR(128),
    Qtd_Linhas BIGINT
);
-- Cursor filtrando apenas bancos onde seu usuário tem acesso
DECLARE db_cursor CURSOR FOR 
SELECT name 
FROM sys.databases 
WHERE state = 0 
  AND database_id > 4 
  AND HAS_DBACCESS(name) = 1; -- Filtro para acessar bancos que o usuarios tem acesso.
DECLARE @dbName NVARCHAR(128);
OPEN db_cursor;
FETCH NEXT FROM db_cursor INTO @dbName;
WHILE @@FETCH_STATUS = 0
BEGIN
    SET @command = '
    SELECT 
        ''' + @dbName + ''',
        s.name,
        t.name,
        p.rows
    FROM [' + @dbName + '].sys.tables t
    INNER JOIN [' + @dbName + '].sys.schemas s ON t.schema_id = s.schema_id
    INNER JOIN [' + @dbName + '].sys.indexes i ON t.object_id = i.object_id
    INNER JOIN [' + @dbName + '].sys.partitions p ON i.object_id = p.object_id AND i.index_id = p.index_id
    WHERE i.type = 0 
      AND t.is_ms_shipped = 0  AND p.rows > 0';
    INSERT INTO @Results
    EXEC sp_executesql @command;
    FETCH NEXT FROM db_cursor INTO @dbName;
END
CLOSE db_cursor;
DEALLOCATE db_cursor;
-- Resultado final focado apenas em HEAPs
SELECT 
    Banco,
    Tabela,
    Qtd_Linhas
FROM @Results
ORDER BY Banco, Qtd_Linhas DESC; 