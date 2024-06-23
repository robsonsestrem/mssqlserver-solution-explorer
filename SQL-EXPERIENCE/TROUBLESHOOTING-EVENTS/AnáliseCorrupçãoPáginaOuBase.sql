	/*******************************************************************************************************************************
	--	ALERTA: PAGINA CORROMPIDA
	*******************************************************************************************************************************/
	SET NOCOUNT ON
		
	SELECT SP.*
	FROM [msdb].[dbo].[suspect_pages] SP


	/*******************************************************************************************************************************
	--	ALERTA: CORRUPÇÃO DE DATABASES
	*******************************************************************************************************************************/
	SET NOCOUNT ON

	SET DATEFORMAT MDY

	IF ( OBJECT_ID('tempdb..#TempLog') IS NOT NULL ) 
		DROP TABLE #TempLog
	
	CREATE TABLE #TempLog (
		[LogDate]		DATETIME,
		[ProcessInfo]	NVARCHAR(50),
		[Text]			NVARCHAR(MAX)
	)

	IF ( OBJECT_ID('tempdb..#logF') IS NOT NULL ) 
		DROP TABLE #logF
	
	CREATE TABLE #logF (
		ArchiveNumber     INT,
		LogDate           DATETIME,
		LogSize           INT 
	)

	-- Seleciona o número de arquivos.
	INSERT INTO #logF  
	EXEC sp_enumerrorlogs
	
	DELETE FROM #logF
	WHERE LogDate < GETDATE()-2

	DECLARE @TSQL NVARCHAR(2000), @lC INT	

	SELECT @lC = MIN(ArchiveNumber) FROM #logF

	--Loop para realizar a leitura de todo o log
	WHILE @lC IS NOT NULL
	BEGIN
		  INSERT INTO #TempLog
		  EXEC sp_readerrorlog @lC
		  
		  SELECT @lC = MIN(ArchiveNumber) 
		  FROM #logF
		  WHERE ArchiveNumber > @lC
	END

	IF OBJECT_ID('_Result_Corrupcao') IS NOT NULL
		DROP TABLE _Result_Corrupcao
		
	SELECT	LogDate,
			SUBSTRING(Text, 15, CHARINDEX(')', Text, 15) - 15) AS Nm_Database,
			SUBSTRING(Text,charindex('found',Text),(charindex('Elapsed time',Text)-charindex('found',Text))) AS Erros,   
			Text 
	INTO _Result_Corrupcao
	FROM #TempLog
	WHERE LogDate >= GETDATE() - 1	 
		and Text like '%DBCC CHECKDB (%'
		and Text not like '%IDR%'
		and substring(Text,charindex('found',Text), charindex('Elapsed time',Text) - charindex('found',Text)) <> 'found 0 errors and repaired 0 errors.'

-- resultado da verificação
select * from _Result_Corrupcao




	