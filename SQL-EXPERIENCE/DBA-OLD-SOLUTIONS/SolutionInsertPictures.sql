/*
 *
    OBJETIVO: Exemplo de carga de arquivos de imagem em formato binário no SQL Server
              usando OPENROWSET BULK e conversão de VARBINARY para string hexadecimal.
    PROJETO: mssqlserver-solution-explorer

    REFERÊNCIAS DE URL:
 *  https://pedrogalvaojunior.wordpress.com/2012/07/20/dica-armazenando-arquivos-de-imagem-no-sql-server-2008-e-r2-atraves-do-comando-openrowset-em-conjunto-com-a-opcao-bulk/
 *  https://basitaalishan.com/2014/09/11/sql-server-converting-binary-data-to-a-hexadecimal-string/
 */
-- ============================================================
-- Bloco 01: Criação da tabela de armazenamento de imagens
-- ============================================================
CREATE TABLE Imagens
(
    Codigo INT IDENTITY(1,1) NOT NULL PRIMARY KEY
  , NomedoArquivo VARCHAR(1000) NOT NULL
  , Arquivo VARBINARY(MAX)
)

-- ============================================================
-- Bloco 02: Inserção da imagem usando OPENROWSET BULK
-- ============================================================
INSERT INTO Imagens
(
    NomedoArquivo
  , Arquivo
)
SELECT
    'robson.png'
  , *
FROM OPENROWSET(BULK N'C:\Data\DatabaseMail\robson.png', SINGLE_BLOB) AS Load;

-- ============================================================
-- Bloco 03: Consulta de validação do conteúdo binário
-- Após isso, nossos dados já estão gravados no SQL Server, o que nos resta é fazer um simples
-- Select consultando os dados nesta tabela que serão apresentados na Coluna Arquivo de forma Binária.
-- Para que você possa apresentar estas imagens de uma forma legível, utilize qualquer aplicação ou
-- gerador de relatórios fazendo uso de componentes do tipo Image, responsáveis em decodificar
-- e converter o conteúdo binário em pontos mapeados conhecidos como bitmap.
-- ============================================================
SELECT *
FROM dbo.Imagens AS i

-- ============================================================
-- Bloco 04: Definição de contexto para a função de conversão
-- ============================================================
USE DBA_PerformanceHub
GO

-- ============================================================
-- Bloco 05: Função para conversão de binário para hexadecimal
-- ============================================================
CREATE FUNCTION Management.[fn_Binvaluetohexdecstr]
(
    @p_binhexvalue [VARBINARY](256)
)
RETURNS [VARCHAR](512)
AS
BEGIN
    -- ============================================================
    -- Declaração de variáveis de apoio da função
    -- ============================================================
    DECLARE @x [XML]
          , @OutPutStrHex [VARCHAR](512)
          , @Version [NUMERIC](18, 1);

    SET @x = '<root></root>';

    -- ============================================================
    -- Calcula a versão principal do SQL Server para definir a estratégia
    -- ============================================================
    SET @Version = CAST(
        LEFT(
            CAST(SERVERPROPERTY(N'ProductVersion') AS [NVARCHAR](128))
          , CHARINDEX(N'.', CAST(SERVERPROPERTY(N'ProductVersion') AS [NVARCHAR](128))) - 1
        ) + N'.'
        + REPLACE(
            RIGHT(
                CAST(SERVERPROPERTY(N'ProductVersion') AS [NVARCHAR](128))
              , LEN(CAST(SERVERPROPERTY(N'ProductVersion') AS [NVARCHAR](128)))
                - CHARINDEX(N'.', CAST(SERVERPROPERTY(N'ProductVersion') AS [NVARCHAR](128)))
            )
          , N'.'
          , N''
        ) AS [NUMERIC](18, 10));

    -- ============================================================
    -- Conversão conforme versão do SQL Server
    -- ============================================================
    IF @Version >= 10.5
    BEGIN
        SELECT @OutPutStrHex = CONVERT([VARCHAR](512), @p_binhexvalue, 1);
    END
    ELSE
    BEGIN
        SELECT @OutPutStrHex = N'0x' + @x.value('xs:hexBinary(sql:variable("@p_binhexvalue"))', '[varchar](512)');
    END

    RETURN
    (
        SELECT @OutPutStrHex
    )
END
GO

-- ============================================================
-- Bloco 06: Teste da função com a imagem carregada
-- ============================================================
DECLARE @teste VARBINARY(MAX) =
(
    SELECT t1.Arquivo
    FROM dbo.Imagens AS t1
)

SELECT Management.fn_Binvaluetohexdecstr(@teste)
