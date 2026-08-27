/*
	OBJETIVO: Consultar informações detalhadas sobre os arquivos de dados e log
			  do banco de dados, incluindo tamanho, espaço utilizado, espaço livre
			  e configurações de autocrescimento (autogrowth).
	PROJETO: mssqlserver-solution-explorer

	REFERÊNCIAS E AUTORIA:
	Script cedido pela TECLÓGICA.
*/
USE YOUR_DATABASE;
GO

SELECT
      A.type_desc                                                                         AS [TYPE]
    , A.name                                                                              AS [FILE_Name]
    , fg.name                                                                             AS [FILEGROUP_NAME]
    , A.physical_name                                                                     AS [File_Location]
    , CONVERT(DECIMAL(10, 2), A.size / 128.0)                                             AS [FILESIZE_MB]
    , CONVERT
      (
          DECIMAL(10, 2)
        , A.size / 128.0 - ((A.size / 128.0) - CAST(FILEPROPERTY(A.name, 'SPACEUSED') AS INT) / 128.0)
      )                                                                                   AS [USEDSPACE_MB]
    , CONVERT
      (
          DECIMAL(10, 2)
        , A.size / 128.0 - CAST(FILEPROPERTY(A.name, 'SPACEUSED') AS INT) / 128.0
      )                                                                                   AS [FREESPACE_MB]
    , CONVERT
      (
          DECIMAL(10, 2)
        , ((A.size / 128.0 - CAST(FILEPROPERTY(A.name, 'SPACEUSED') AS INT) / 128.0) / (A.size / 128.0)) * 100
      )                                                                                   AS [FREESPACE_%]
    , 'By '
      + CASE A.is_percent_growth
            WHEN 0
            THEN CAST(A.growth / 128 AS VARCHAR(10)) + ' MB -'
            WHEN 1
            THEN CAST(A.growth AS VARCHAR(10)) + '% -'
            ELSE ''
        END
      + CASE A.max_size
            WHEN 0
            THEN 'DISABLED'
            WHEN -1
            THEN 'Unrestricted'
            ELSE 'Restricted to ' + CAST(A.max_size / (128 * 1024) AS VARCHAR(10)) + ' GB'
        END
      + CASE A.is_percent_growth
            WHEN 1
            THEN ' [autogrowth by percent, BAD setting!]'
            ELSE ''
        END                                                                               AS [AutoGrow]
FROM sys.database_files                                                                   AS A
LEFT JOIN sys.filegroups                                                                  AS fg
        ON A.data_space_id = fg.data_space_id
WHERE A.type_desc = 'LOG'                                                                -- Filtro para arquivos de log
ORDER BY
      A.name;
