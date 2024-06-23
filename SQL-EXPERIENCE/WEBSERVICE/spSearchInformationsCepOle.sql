--------------------------------------------------------------------------------------------------------------------------------
-- https://www.dirceuresende.com/blog/como-consultar-informacoes-de-um-cep-no-sql-server/
--------------------------------------------------------------------------------------------------------------------------------
-- PROCEDURE OLE AUTOMATION

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

use IntegraTICravil
go

alter PROCEDURE Management.sp_SearchInformationsCEP_OLE (
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
 
 
    -- Recupera apenas os n??os do CEP
    DECLARE @startingIndex INT = 0
    
    WHILE (1=1)
    BEGIN
      
        SET @startingIndex = PATINDEX('%[^0-9]%', @Nr_CEP)  
        
        IF (@startingIndex <> 0)
            SET @Nr_CEP = REPLACE(@Nr_CEP, SUBSTRING(@Nr_CEP, @startingIndex, 1), '')  
        ELSE    
            BREAK
            
    END
    
    
    
    SET @Url = 'http://viacep.com.br/ws/' + @Nr_CEP + '/xml'
 
    EXEC sys.sp_OACreate 'MSXML2.ServerXMLHTTP', @obj OUT
    EXEC sys.sp_OAMethod @obj, 'open', NULL, 'GET', @Url, FALSE
    EXEC sys.sp_OAMethod @obj, 'send'
    EXEC sys.sp_OAGetProperty @obj, 'responseText', @resposta OUT
    EXEC sys.sp_OADestroy @obj
    
    SET @xml = @resposta COLLATE SQL_Latin1_General_CP1251_CS_AS
    
    SELECT
        @xml.value('(/xmlcep/cep)[1]', 'varchar(9)') AS CEP,
        @xml.value('(/xmlcep/logradouro)[1]', 'varchar(200)') AS Logradouro,
        @xml.value('(/xmlcep/complemento)[1]', 'varchar(200)') AS Complemento,
        @xml.value('(/xmlcep/bairro)[1]', 'varchar(200)') AS Bairro,
        @xml.value('(/xmlcep/localidade)[1]', 'varchar(200)') AS Cidade,
        @xml.value('(/xmlcep/uf)[1]', 'varchar(200)') AS UF,
        @xml.value('(/xmlcep/ibge)[1]', 'varchar(200)') AS IBGE 

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


--------------------------------------------------------------------------------------------------------------------------------
-- Exemplo
--------------------------------------------------------------------------------------------------------------------------------
execute Management.sp_SearchInformationsCEP_OLE 
@Nr_CEP = '89163020'


------------------------------------------------------------------------------------------------------------------------------------------
-- Get sem tratamento
------------------------------------------------------------------------------------------------------------------------------------------
 --   DECLARE 
 --       @obj INT,
 --       @Url VARCHAR(255),
 --       @resposta VARCHAR(8000),
 --       @xml XML,
	--	@Nr_CEP varchar(20) = '89170000'

	--SET @Url = 'http://viacep.com.br/ws/' + @Nr_CEP + '/xml'
 
 --   EXEC sys.sp_OACreate 'MSXML2.ServerXMLHTTP', @obj OUT
 --   EXEC sys.sp_OAMethod @obj, 'open', NULL, 'GET', @Url, FALSE
 --   EXEC sys.sp_OAMethod @obj, 'send'
 --   EXEC sys.sp_OAGetProperty @obj, 'responseText', @resposta OUT
 --   EXEC sys.sp_OADestroy @obj
    
 --   SET @xml = @resposta COLLATE SQL_Latin1_General_CP1251_CS_AS

	--select @resposta