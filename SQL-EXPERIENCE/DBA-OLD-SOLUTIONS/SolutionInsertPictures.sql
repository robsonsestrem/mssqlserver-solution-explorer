--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Referência -> https://pedrogalvaojunior.wordpress.com/2012/07/20/dica-armazenando-arquivos-de-imagem-no-sql-server-2008-e-r2-atraves-do-comando-openrowset-em-conjunto-com-a-opcao-bulk/
-- https://basitaalishan.com/2014/09/11/sql-server-converting-binary-data-to-a-hexadecimal-string/
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Create Table Imagens

(

Codigo Int Identity(1,1) Not Null Primary Key,

NomedoArquivo Varchar(1000) Not Null,

Arquivo Varbinary(Max)

)


INSERT INTO Imagens(NomedoArquivo, Arquivo)

SELECT 'robson.png', *

FROM OPENROWSET(BULK N'C:\DBACravil\DatabaseMail\robson.png',  SINGLE_BLOB) Load;


--Após isso, nossos dados já estão gravados no SQL Server, o que nos resta é fazer um simples 
--Select consultando os dados nesta tabela que serão apresentados na Coluna Arquivo de forma Binária. 
--Para que você possa apresentar estas imagens de uma forma legível, utilize qualquer aplicação ou 
--gerador de relatórios fazendo uso de componentes do tipo Image, responsáveis em decodificar 
--e converter o conteúdo binário em pontos mapeados conhecidos como bitmap.


SELECT * FROM dbo.Imagens i


--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
USE IntegraTICravil
GO

CREATE FUNCTION Management.[fn_Binvaluetohexdecstr] (@p_binhexvalue [varbinary](256))
RETURNS [varchar](512)
AS
    BEGIN
 
        DECLARE @x              [xml] ,
                @OutPutStrHex   [varchar](512) ,
                @Version        [numeric](18, 1);
 
        SET @x = '<root></root>';
        SET @Version = CAST(LEFT(CAST(SERVERPROPERTY(N'ProductVersion') AS [nvarchar](128)),
                        CHARINDEX(N'.', CAST(SERVERPROPERTY(N'ProductVersion') AS [nvarchar](128))) - 1) + N'.'
                        + REPLACE(RIGHT(CAST(SERVERPROPERTY(N'ProductVersion') AS [nvarchar](128)),
                        LEN(CAST(SERVERPROPERTY(N'ProductVersion') AS [nvarchar](128)))
                        - CHARINDEX(N'.', CAST(SERVERPROPERTY(N'ProductVersion') AS [nvarchar](128)))), N'.', N'') AS [numeric](18, 10));
                 
        IF @Version >= 10.5
            BEGIN
                SELECT  @OutPutStrHex = CONVERT([varchar](512), @p_binhexvalue, 1);
            END
        ELSE
            BEGIN
                SELECT  @OutPutStrHex = N'0x' + @x.value('xs:hexBinary(sql:variable("@p_binhexvalue"))',
                                                         '[varchar](512)');
            END
         
        RETURN (SELECT @OutPutStrHex) 
    END
GO
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
DECLARE @teste varbinary(max) = (SELECT t1.Arquivo FROM dbo.Imagens AS t1)
SELECT Management.fn_Binvaluetohexdecstr(@teste)
