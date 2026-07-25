/*
    OBJETIVO: Consultar informações de um CEP utilizando a API Bemean (JSON) via OLE Automation
              (sp_OACreate), incluindo lógica para habilitar e desabilitar temporariamente as
              Ole Automation Procedures. Requer SQL Server 2016 ou superior para funções JSON.
    PROJETO: mssqlserver-solution-explorer
    
    REFERÊNCIAS DE URL:
    https://www.dirceuresende.com/blog/sql-server-2016-como-consultar-informacoes-de-um-cep-utilizando-a-api-bemean-e-a-funcao-json_value/
*/
-- ============================================================
-- Procedimento armazenado para busca de CEP via API JSON
-- ============================================================

CREATE OR ALTER PROCEDURE Management.sp_SearchInformationsCEP_OLE_JSON (
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

    -- Declaração das variáveis para requisição HTTP e manipulação de resposta
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

    -- Monta a URL da API Bemean e executa a requisição HTTP via OLE Automation
    SET @Url = 'https://cep-bemean.herokuapp.com/api/br/' + @Nr_CEP;

    EXECUTE sys.sp_OACreate 'MSXML2.ServerXMLHTTP', @obj OUT;
    EXECUTE sys.sp_OAMethod @obj, 'open', NULL, 'GET', @Url, FALSE;
    EXECUTE sys.sp_OAMethod @obj, 'send';
    EXECUTE sys.sp_OAGetProperty @obj, 'responseText', @resposta OUT;
    EXECUTE sys.sp_OADestroy @obj;

    -- Extrai os dados do JSON de resposta e retorna como conjunto de resultados
    SELECT 
        JSON_VALUE(@resposta, '$.code') AS CEP
        , JSON_VALUE(@resposta, '$.address') AS Logradouro
        , JSON_VALUE(@resposta, '$.district') AS Bairro
        , JSON_VALUE(@resposta, '$.city') AS Cidade
        , JSON_VALUE(@resposta, '$.state') AS Estado;

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
EXECUTE Management.sp_SearchInformationsCEP_OLE_JSON
    @Nr_CEP = '89173000';

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
-- SET @Url = 'https://cep-bemean.herokuapp.com/api/br/' + @Nr_CEP;
--
-- EXECUTE sys.sp_OACreate 'MSXML2.ServerXMLHTTP', @obj OUT;
-- EXECUTE sys.sp_OAMethod @obj, 'open', NULL, 'GET', @Url, FALSE;
-- EXECUTE sys.sp_OAMethod @obj, 'send';
-- EXECUTE sys.sp_OAGetProperty @obj, 'responseText', @resposta OUT;
-- EXECUTE sys.sp_OADestroy @obj;
--
-- SELECT @resposta;
