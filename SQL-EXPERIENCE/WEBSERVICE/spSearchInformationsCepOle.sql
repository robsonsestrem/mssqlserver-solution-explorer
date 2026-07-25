/*
    OBJETIVO: Consultar informações de um CEP utilizando a API ViaCEP (XML) via OLE Automation
              (sp_OACreate), incluindo lógica para habilitar e desabilitar temporariamente as
              Ole Automation Procedures.
    PROJETO: mssqlserver-solution-explorer

    REFERÊNCIAS DE URL:
    https://www.dirceuresende.com/blog/como-consultar-informacoes-de-um-cep-no-sql-server/
*/
-- ============================================================
-- PROCEDURE OLE AUTOMATION
-- Ativando parâmetros relacionados
-- ============================================================
--sp_configure 'show advanced options', 1;
--GO
--RECONFIGURE;
--GO
--sp_configure 'Ole Automation Procedures', 1;
--GO
--RECONFIGURE;
--GO
--sp_configure 'Agent XPs', 1;
--GO
--RECONFIGURE;
--GO
--sp_configure 'show advanced options', 1;
--GO
--RECONFIGURE;
--GO

USE YOUR_DATABASE;
GO

CREATE OR ALTER PROCEDURE Management.sp_SearchInformationsCEP_OLE (
    @Nr_CEP VARCHAR(20)
)
WITH ENCRYPTION
AS
BEGIN
    SET NOCOUNT ON;

    -- Verifica se o OLE Automation está habilitado para restaurar o estado original ao final
    DECLARE @Fl_Ole_Automation_Ativado BIT;

    SET @Fl_Ole_Automation_Ativado = (
        SELECT CASE 
                   WHEN CAST([value] AS VARCHAR(MAX)) = '1' THEN 1 
                   ELSE 0 
               END
        FROM sys.configurations 
        WHERE [name] = 'Ole Automation Procedures'
    );

    IF (@Fl_Ole_Automation_Ativado = 0)
    BEGIN
        EXECUTE sp_configure 'show advanced options', 1;
        RECONFIGURE WITH OVERRIDE;
        EXECUTE sp_configure 'Ole Automation Procedures', 1;
        RECONFIGURE WITH OVERRIDE;
    END;

    -- Declaração das variáveis para requisição HTTP e manipulação de XML
    DECLARE @obj INT;
    DECLARE @Url VARCHAR(255);
    DECLARE @resposta VARCHAR(8000);
    DECLARE @xml XML;
    DECLARE @startingIndex INT;

    -- Remove caracteres não numéricos do CEP fornecido
    SET @startingIndex = 0;

    WHILE (1 = 1)
    BEGIN
        SET @startingIndex = PATINDEX('%[^0-9]%', @Nr_CEP);
        
        IF (@startingIndex <> 0)
        BEGIN
            SET @Nr_CEP = REPLACE(@Nr_CEP, SUBSTRING(@Nr_CEP, @startingIndex, 1), '');
        END;
        ELSE
        BEGIN
            BREAK;
        END;
    END;

    -- Monta a URL da API ViaCEP e executa a requisição HTTP via OLE Automation
    SET @Url = 'http://viacep.com.br/ws/' + @Nr_CEP + '/xml';

    EXECUTE sys.sp_OACreate 'MSXML2.ServerXMLHTTP', @obj OUT;
    EXECUTE sys.sp_OAMethod @obj, 'open', NULL, 'GET', @Url, FALSE;
    EXECUTE sys.sp_OAMethod @obj, 'send';
    EXECUTE sys.sp_OAGetProperty @obj, 'responseText', @resposta OUT;
    EXECUTE sys.sp_OADestroy @obj;

    SET @xml = @resposta COLLATE SQL_Latin1_General_CP1251_CS_AS;

    -- Extrai os dados do XML de resposta e retorna como conjunto de resultados
    SELECT 
        @xml.value('(/xmlcep/cep)[1]', 'VARCHAR(9)') AS CEP
        , @xml.value('(/xmlcep/logradouro)[1]', 'VARCHAR(200)') AS Logradouro
        , @xml.value('(/xmlcep/complemento)[1]', 'VARCHAR(200)') AS Complemento
        , @xml.value('(/xmlcep/bairro)[1]', 'VARCHAR(200)') AS Bairro
        , @xml.value('(/xmlcep/localidade)[1]', 'VARCHAR(200)') AS Cidade
        , @xml.value('(/xmlcep/uf)[1]', 'VARCHAR(200)') AS UF
        , @xml.value('(/xmlcep/ibge)[1]', 'VARCHAR(200)') AS IBGE;

    -- Desativa o OLE Automation apenas se não estava habilitado antes da execução
    IF (@Fl_Ole_Automation_Ativado = 0)
    BEGIN
        EXECUTE sp_configure 'Ole Automation Procedures', 0;
        RECONFIGURE WITH OVERRIDE;
        EXECUTE sp_configure 'show advanced options', 0;
        RECONFIGURE WITH OVERRIDE;
    END;
END;
GO

-- ============================================================
-- Exemplo de execução da procedure
-- ============================================================
EXECUTE Management.sp_SearchInformationsCEP_OLE
    @Nr_CEP = '89163020';

-- ============================================================
-- Exemplo de execução sem tratamento (Get sem tratamento)
-- ============================================================
-- DECLARE
--     @obj INT,
--     @Url VARCHAR(255),
--     @resposta VARCHAR(8000),
--     @xml XML,
--     @Nr_CEP VARCHAR(20) = '89170000';
--
-- SET @Url = 'http://viacep.com.br/ws/' + @Nr_CEP + '/xml';
--
-- EXECUTE sys.sp_OACreate 'MSXML2.ServerXMLHTTP', @obj OUT;
-- EXECUTE sys.sp_OAMethod @obj, 'open', NULL, 'GET', @Url, FALSE;
-- EXECUTE sys.sp_OAMethod @obj, 'send';
-- EXECUTE sys.sp_OAGetProperty @obj, 'responseText', @resposta OUT;
-- EXECUTE sys.sp_OADestroy @obj;
--
-- SET @xml = @resposta COLLATE SQL_Latin1_General_CP1251_CS_AS;
--
-- SELECT @resposta;
