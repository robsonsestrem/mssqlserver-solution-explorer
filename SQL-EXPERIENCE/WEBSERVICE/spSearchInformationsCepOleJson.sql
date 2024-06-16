------------------------------------------------------------------------------------------------------------------------------------------
-- https://www.dirceuresende.com/blog/sql-server-2016-como-consultar-informacoes-de-um-cep-utilizando-a-api-bemean-e-a-funcao-json_value/
-- ESTA COLETA SÓ FUNCIONA EM VERSÕES MAIS ATUAIS DO SQL SERVER, POIS USA JSON no lugar de XML
------------------------------------------------------------------------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE Management.sp_SearchInformationsCEP_OLE_JSON (
    @Nr_CEP VARCHAR(20)
)
with encryption
AS BEGIN

    --------------------------------------------------------------------------------
    -- Habilitando o OLE Automation (Se não estiver ativado)
    --------------------------------------------------------------------------------

    DECLARE @Fl_Ole_Automation_Ativado BIT = (SELECT (CASE WHEN CAST([value] AS VARCHAR(MAX)) = '1' THEN 1 ELSE 0 END) FROM sys.configurations WHERE [name] = 'Ole Automation Procedures')
 
    IF (@Fl_Ole_Automation_Ativado = 0)
    BEGIN
 
        EXECUTE SP_CONFIGURE 'show advanced options', 1;
        RECONFIGURE WITH OVERRIDE;
    
        EXEC sp_configure 'Ole Automation Procedures', 1;
        RECONFIGURE WITH OVERRIDE;
    
    END


    DECLARE 
        @obj INT,
        @Url VARCHAR(255),
        @resposta VARCHAR(8000),
        @xml XML
 
 
    -- Recupera apenas os números do CEP
    DECLARE @startingIndex INT = 0
    
    WHILE (1=1)
    BEGIN
      
        SET @startingIndex = PATINDEX('%[^0-9]%', @Nr_CEP)  
        
        IF (@startingIndex <> 0)
            SET @Nr_CEP = REPLACE(@Nr_CEP, SUBSTRING(@Nr_CEP, @startingIndex, 1), '')  
        ELSE    
            BREAK
            
    END
    
    
    
    SET @Url = 'https://cep-bemean.herokuapp.com/api/br/' + @Nr_CEP
 
    EXEC sys.sp_OACreate 'MSXML2.ServerXMLHTTP', @obj OUT
    EXEC sys.sp_OAMethod @obj, 'open', NULL, 'GET', @Url, FALSE
    EXEC sys.sp_OAMethod @obj, 'send'
    EXEC sys.sp_OAGetProperty @obj, 'responseText', @resposta OUT
    EXEC sys.sp_OADestroy @obj
    
    SELECT
        JSON_VALUE(@resposta, '$.code') AS CEP,
        JSON_VALUE(@resposta, '$.address') AS Logradouro,
        JSON_VALUE(@resposta, '$.district') AS Bairro,
        JSON_VALUE(@resposta, '$.city') AS Cidade,
        JSON_VALUE(@resposta, '$.state') AS Estado



    --------------------------------------------------------------------------------
    -- Desativando o OLE Automation (Se não estava habilitado antes)
    --------------------------------------------------------------------------------

    IF (@Fl_Ole_Automation_Ativado = 0)
    BEGIN

        EXEC sp_configure 'Ole Automation Procedures', 0;
        RECONFIGURE WITH OVERRIDE;

        EXECUTE SP_CONFIGURE 'show advanced options', 0;
        RECONFIGURE WITH OVERRIDE;

    END

END


------------------------------------------------------------------------------------------------------------------------------------------
-- Exemplo
------------------------------------------------------------------------------------------------------------------------------------------
execute Management.sp_SearchInformationsCEP_OLE_JSON
@Nr_CEP = '89173000'


------------------------------------------------------------------------------------------------------------------------------------------
-- Get sem tratamento
------------------------------------------------------------------------------------------------------------------------------------------
--DECLARE 
--        @obj INT,
--        @Url VARCHAR(255),
--        @resposta VARCHAR(8000),
--        @xml XML,
--		@Nr_CEP varchar(20) = '89170000'
--	SET @Url = 'https://cep-bemean.herokuapp.com/api/br/' + @Nr_CEP
 
--    EXEC sys.sp_OACreate 'MSXML2.ServerXMLHTTP', @obj OUT
--    EXEC sys.sp_OAMethod @obj, 'open', NULL, 'GET', @Url, FALSE
--    EXEC sys.sp_OAMethod @obj, 'send'
--    EXEC sys.sp_OAGetProperty @obj, 'responseText', @resposta OUT
--    EXEC sys.sp_OADestroy @obj

--	select @resposta