/*
    OBJETIVO: Consultar API do Google Maps para obter informações de geocodificação a partir de um CEP ou endereço, retornando os dados estruturados em formato de tabela.
    PROJETO: mssqlserver-solution-explorer
    -- Referências:
    -- https://www.dirceuresende.com/blog/consumindo-a-api-do-google-maps-para-obter-informacoes-de-um-endereco-ou-cep-no-sql-server/    
*/
USE YOUR_DATABASE;
GO

CREATE OR ALTER PROCEDURE Management.sp_SearchInformationsCEP (
    @Ds_Endereco VARCHAR(500) = NULL,
    @Nr_Cep VARCHAR(9) = NULL
)
WITH ENCRYPTION
AS
BEGIN
    SET NOCOUNT ON;

    -- Validação e limpeza dos parâmetros de entrada
    SET @Ds_Endereco = NULLIF(@Ds_Endereco, '');
    SET @Nr_Cep = NULLIF(@Nr_Cep, '');

    IF (@Ds_Endereco IS NULL AND @Nr_Cep IS NULL)
    BEGIN
        RETURN;
    END;

    -- Declaração das variáveis necessárias para a requisição HTTP e tratamento de XML
    DECLARE 
        @obj INT,
        @Url VARCHAR(8000),
        @resposta VARCHAR(8000),
        @xml XML,
        @endereco_busca VARCHAR(4000);

    -- Montagem da string de busca para a API do Google Maps
    IF (@Nr_Cep IS NOT NULL AND @Ds_Endereco IS NULL)
    BEGIN
        SET @endereco_busca = LEFT(@Nr_Cep, 5) + '-' + RIGHT(@Nr_Cep, 3) + ', Brasil';
    END
    ELSE
    BEGIN
        SET @endereco_busca = @Ds_Endereco;
    END;

    SET @Url = 'http://maps.googleapis.com/maps/api/geocode/xml?address=' + @endereco_busca + '&sensor=false';

    -- Execução da requisição HTTP via OLE Automation Procedures
    EXEC sys.sp_OACreate @progid = 'MSXML2.ServerXMLHTTP', @objecttoken = @obj OUT, @context = 1;
    EXEC sys.sp_OAMethod @obj, 'open', NULL, 'GET', @Url, false;
    EXEC sys.sp_OAMethod @obj, 'send';
    EXEC sys.sp_OAGetProperty @obj, 'responseText', @resposta OUT;
    EXEC sys.sp_OADestroy @obj;

    SET @xml = @resposta COLLATE SQL_Latin1_General_CP1251_CS_AS;

    -- Extração dos componentes de endereço do XML de resposta
    IF (OBJECT_ID('tempdb..#XML') IS NOT NULL)
    BEGIN
        DROP TABLE #XML;
    END;

    CREATE TABLE #XML (
        Dados XML
    );

    INSERT INTO #XML (Dados)
    SELECT 
        Tabela.coluna.query('.') AS Resultado
    FROM 
        @xml.nodes('/GeocodeResponse/result/address_component') AS Tabela(coluna);

    -- Criação da tabela temporária para estruturar os dados extraídos
    IF (OBJECT_ID('tempdb..#Endereco') IS NOT NULL)
    BEGIN
        DROP TABLE #Endereco;
    END;

    CREATE TABLE #Endereco (
        Ds_Tipo VARCHAR(100),
        Ds_Subtipo VARCHAR(100),
        Ds_ShortName VARCHAR(200),
        Ds_ShortName2 VARCHAR(200),
        Ds_LongName VARCHAR(500)
    );

    -- Inserção dos componentes de endereço mapeados do XML
    INSERT INTO #Endereco (
        Ds_Tipo,
        Ds_Subtipo,
        Ds_ShortName,
        Ds_ShortName2,
        Ds_LongName
    )
    SELECT 
        Dados.query('address_component/type[1]').value('.', 'varchar(100)') AS Ds_Tipo
        , Dados.query('address_component/type[2]').value('.', 'varchar(100)') AS Ds_Subtipo
        , Dados.query('address_component/type[3]').value('.', 'varchar(100)') AS Ds_ShortName
        , Dados.query('address_component/short_name').value('.', 'varchar(200)') AS Ds_ShortName2
        , Dados.query('address_component/long_name').value('.', 'varchar(500)') AS Ds_LongName
    FROM 
        #XML;

    -- Inserção do endereço formatado completo retornado pela API
    INSERT INTO #Endereco (
        Ds_Tipo,
        Ds_Subtipo,
        Ds_ShortName,
        Ds_ShortName2,
        Ds_LongName
    )
    SELECT 
        'formatted_address' AS Ds_Tipo
        , 'formatted_address' AS Ds_Subtipo
        , '' AS Ds_ShortName
        , '' AS Ds_ShortName2
        , @xml.value('(/GeocodeResponse/result/formatted_address)[1]', 'varchar(500)') AS Ds_LongName;

    -- Inserção das coordenadas geográficas (latitude e longitude)
    INSERT INTO #Endereco (
        Ds_Tipo,
        Ds_Subtipo,
        Ds_ShortName,
        Ds_ShortName2,
        Ds_LongName
    )
    SELECT 
        'latlon' AS Ds_Tipo
        , 'latitude_longitude' AS Ds_Subtipo
        , '' AS Ds_ShortName
        , @xml.value('(/GeocodeResponse/result/geometry/location/lat)[1]', 'varchar(100)') AS Ds_ShortName2
        , @xml.value('(/GeocodeResponse/result/geometry/location/lng)[1]', 'varchar(100)') AS Ds_LongName;

    -- Consolidação e pivô dos dados para o resultado final em formato de coluna
    SELECT 
        MAX(CASE WHEN Ds_Tipo = 'formatted_address' THEN Ds_LongName END) AS Ds_Endereco_Completo
        , MAX(CASE WHEN Ds_Tipo = 'route' THEN Ds_LongName END) AS Ds_Logradouro
        , MAX(CASE WHEN Ds_Tipo = 'street_number' THEN Ds_LongName END) AS Ds_Numero
        , MAX(CASE 
                WHEN Ds_Tipo = 'sublocality_level_1' 
                    OR Ds_Subtipo = 'sublocality_level_1' 
                    OR Ds_ShortName = 'sublocality_level_1' THEN Ds_LongName 
            END) AS Ds_Bairro
        , MAX(CASE WHEN Ds_Tipo = 'administrative_area_level_2' THEN Ds_LongName END) AS Ds_Cidade
        , MAX(CASE WHEN Ds_Tipo = 'postal_code' THEN Ds_LongName END) AS Ds_CEP
        , MAX(CASE WHEN Ds_Tipo = 'administrative_area_level_1' THEN Ds_ShortName END) AS Ds_Estado_Sigla
        , MAX(CASE WHEN Ds_Tipo = 'administrative_area_level_1' THEN Ds_LongName END) AS Ds_Estado
        , MAX(CASE WHEN Ds_Tipo = 'country' THEN Ds_ShortName END) AS Ds_Pais_Sigla
        , MAX(CASE WHEN Ds_Tipo = 'country' THEN Ds_LongName END) AS Ds_Pais
        , MAX(CASE WHEN Ds_Tipo = 'latlon' THEN Ds_ShortName END) AS Ds_Latitude
        , MAX(CASE WHEN Ds_Tipo = 'latlon' THEN Ds_LongName END) AS Ds_Longitude
    FROM 
        #Endereco;
END;
GO

-- Exemplo de execução
EXECUTE Management.sp_SearchInformationsCEP
    -- @Ds_Endereco = '%Pte. do Imaruim, Palhoca - SC, Brasil%' -- nome da rua/estrada/beco
    @Nr_Cep = '89160000'; -- cep