/*
 *
    OBJETIVO: Stored procedure para exportar uma string para arquivo em disco
              utilizando OLE Automation (Scripting.FileSystemObject).
              Recebe o conteúdo e o caminho destino, cria o arquivo via
              CreateTextFile e escreve os dados via método Write do FSO.
    PROJETO: mssqlserver-solution-explorer

    REFERÊNCIAS DE URL:
 *  https://www.dirceuresende.com/blog/sql-server-como-exportar-dados-do-banco-para-arquivo-texto-clr-ole-bcp/
 */
-- ============================================================
-- Exportação de String para Arquivo via OLE Automation
-- ============================================================

-- EXEMPLO DE USO — 01: Exportando uma string simples para arquivo
-- DECLARE @Texto VARCHAR(MAX) = 'Teste
-- de arquivo
-- com quebra
-- de
-- linhas
-- '
-- EXEC Management.[sp_Escreve_Arquivo_FSO]
--       @String = @Texto
--     , @Ds_Arquivo = 'C:\Temp\Teste.txt'

-- EXEMPLO DE USO — 02: Exportando XML de NF-e para arquivo
-- EXEC Management.[sp_Escreve_Arquivo_FSO]
--       @String = '<nfeProc xmlns="http://www.portalfiscal.inf.br/nfe" versao="3.10">
--                  ...[XML completo no arquivo original — truncado para legibilidade]...
--                  </nfeProc>'
--     , @Ds_Arquivo = 'C:\Temp\Teste.xml'

-- Criação/alteração da procedure de exportação de arquivo via FileSystemObject
CREATE OR ALTER PROCEDURE Management.[sp_Escreve_Arquivo_FSO] (
      @String     VARCHAR(MAX)
    , @Ds_Arquivo VARCHAR(1501)
)
AS
BEGIN
    -- Declaração das variáveis de controle OLE e status de operação
    -- OBS: @Command está declarada mas não é utilizada no corpo da procedure
    DECLARE
          @objFileSystem   INT
        , @objTextStream   INT
        , @objErrorObject  INT
        , @strErrorMessage VARCHAR(1000)
        , @Command         VARCHAR(1000)
        , @hr              INT;

    SET NOCOUNT ON;

    -- Inicializa a mensagem de erro padrão antes de criar o objeto
    SELECT @strErrorMessage = 'opening the File System Object';

    -- Cria o objeto FileSystemObject via OLE Automation
    EXECUTE @hr = sp_OACreate
          'Scripting.FileSystemObject'
        , @objFileSystem OUT;

    -- Registra contexto de erro antes da criação do arquivo
    IF @hr = 0
    BEGIN
        SELECT
              @objErrorObject  = @objFileSystem
            , @strErrorMessage = 'Creating file ' + @Ds_Arquivo + '';
    END

    -- Cria o arquivo texto no disco (overwrite = 2, unicode = True)
    IF @hr = 0
    BEGIN
        EXECUTE @hr = sp_OAMethod
              @objFileSystem
            , 'CreateTextFile'
            , @objTextStream OUT
            , @Ds_Arquivo
            , 2
            , True;
    END

    -- Registra contexto de erro antes de gravar o conteúdo
    IF @hr = 0
    BEGIN
        SELECT
              @objErrorObject  = @objTextStream
            , @strErrorMessage = 'writing to the file ' + @Ds_Arquivo + '';
    END

    -- Escreve a string no arquivo aberto
    IF @hr = 0
    BEGIN
        EXECUTE @hr = sp_OAMethod
              @objTextStream
            , 'Write'
            , NULL
            , @String;
    END

    -- Registra contexto de erro antes de fechar o arquivo
    IF @hr = 0
    BEGIN
        SELECT
              @objErrorObject  = @objTextStream
            , @strErrorMessage = 'closing the file ' + @Ds_Arquivo + '';
    END

    -- Fecha o stream após a escrita
    IF @hr = 0
    BEGIN
        EXECUTE @hr = sp_OAMethod
              @objTextStream
            , 'Close';
    END

    -- Tratamento de erro: captura detalhes OLE e lança exceção
    IF @hr <> 0
    BEGIN
        DECLARE
              @Source      VARCHAR(255)
            , @Description VARCHAR(255)
            , @Helpfile    VARCHAR(255)
            , @HelpID      INT;

        -- Obtém informações detalhadas do erro a partir do objeto com falha
        EXECUTE sp_OAGetErrorInfo
              @objErrorObject
            , @source      OUTPUT
            , @Description OUTPUT
            , @Helpfile    OUTPUT
            , @HelpID      OUTPUT;

        -- Compõe a mensagem de erro com contexto e descrição OLE
        SELECT @strErrorMessage =
            'Error whilst ' + COALESCE(@strErrorMessage, 'doing something')
            + ', ' + COALESCE(@Description, '');

        RAISERROR (@strErrorMessage, 16, 1);
    END

    -- Libera os objetos OLE da memória após a escrita
    EXECUTE sp_OADestroy @objTextStream;
    EXECUTE sp_OADestroy @objFileSystem;
END
GO
