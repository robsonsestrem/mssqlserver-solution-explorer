/************************************************	USANDO BUSCA EM ARQUIVOS DE LOGS	*******************************************************/
/*
    https://www.ibm.com/developerworks/community/blogs/fd26864d-cb41-49cf-b719-d89c6b072893/entry/consultando_o_log_de_erro_do_sql_server_usando_t_sql2?lang=en
	Autor: Adeilson Rocha Brito
	Atualiza��es desta SP podem ser obtidas em:
		http://adeilsonrbrito.wordpress.com

	Descri��o
	=========
	SP para consulta personalizada do log de erro do SQL Server

	Orienta��es
	===========
	Recomendo que voc� crie essa SP na system database MASTER ou em um banco de dados com fins administrativos.

	Notas
	===========
	a) Todos os par�metros desta SP s�o opcionais.
	b) Esta SP pesquisa apenas o log de erro corrente (arquivo 0).

	Exemplos
	========
	-- Pesquisando no log a ocorr�ncia da palavra 'database' nos �ltimos 60 minutos
	exec dbo.sp_ErrorLog 60, null, null, null, 'database'

	-- Listando os registros do log dos �ltimos 5 minutos, do servidor NOTEWIN7\SQL2012
	exec dbo.sp_ErrorLog 5, null, null, null, null, 'NOTEWIN7\SQL2012'
*/
--------------------------------------------------------------------------------------------------------------------------------------------------
USE YOUR_DATABASE
GO

IF OBJECT_ID('Management.sp_ErrorLog') IS NOT NULL
DROP PROCEDURE Management.sp_ErrorLog;
GO

CREATE OR ALTER PROCEDURE Management.sp_ErrorLog
(
	-- Quantidade de minutos a retroagir na pesquisa.
	-- O Default s�o 30 minutos
	-- Informe NULL para desconsiderar e n�o usar este par�metro
	@MinutosRetroagir INT = 30,

	-- Data inicial para a pesquisa no log.
	-- Registros com datas menores ser�o desconsiderados
	-- O Default � NULL
	-- Informe NULL para desconsiderar e n�o usar este par�metro
	@DataInicial DATETIME = NULL,

	-- Data final para a pesquisa no log.
	-- Registros com datas maiores ser�o desconsiderados
	-- O Default � NULL
	-- Informe NULL para desconsiderar e n�o usar este par�metro
	@DataFinal DATETIME = NULL,

	-- Texto a ser pesquisado dentro da coluna ProcessInfo do log
	-- Exemplo: Server, Backup, SPID, etc.
	-- A pesquisa pelo texto � parcial (em qualquer parte)
	-- O Default � NULL
	-- Informe NULL para desconsiderar e n�o usar este par�metro
	@Processo VARCHAR(50) = NULL,

	-- Texto a ser pesquisado dentro da coluna Text do log
	-- Exemplo: error, starting, etc.
	-- A pesquisa pelo texto � parcial (em qualquer parte)
	-- O Default � NULL
	-- Informe NULL para desconsiderar e n�o usar este par�metro
	@Texto VARCHAR(100) = NULL,

	-- Filtra a pesquisa para exibir apenas o log do nome do servidor informado
	-- Use este par�metro quando estiver pesquisando o log de v�rios servidores ao mesmo tempo
	-- O Default � NULL
	-- Informe NULL para desconsiderar e n�o usar este par�metro
	@NomeServidor VARCHAR(128) = NULL
)
WITH ENCRYPTION
AS
		DECLARE @Tmp TABLE
		(    ID INT IDENTITY,
		Data DATETIME,
		Processo VARCHAR(50),
		Texto VARCHAR(4000)
		);
		INSERT INTO @Tmp (Data, Processo, Texto) exec sp_readerrorlog;

		SELECT * FROM @Tmp t
		WHERE t.Data =
		CASE WHEN @MinutosRetroagir IS NOT NULL THEN DATEADD(MINUTE, -@MinutosRetroagir, GETDATE())
		ELSE t.Data END

		AND t.Data = ISNULL(@DataInicial, t.Data)

		AND t.Data = ISNULL(@DataFinal, t.Data)

		AND t.Processo LIKE
		CASE WHEN @Processo IS NOT NULL THEN '%' + @Processo + '%'
		ELSE t.Processo END

		AND t.Texto LIKE
		CASE WHEN @Texto IS NOT NULL THEN '%' + @Texto + '%'
		ELSE t.Texto END

		AND SERVERPROPERTY('ServerName') =
		ISNULL(@NomeServidor, CONVERT(VARCHAR(128), SERVERPROPERTY('ServerName')))

		ORDER BY t.ID DESC;

GO
-- Teste
-- exec Management.sp_ErrorLog null, null, null, null, 'trace', null


