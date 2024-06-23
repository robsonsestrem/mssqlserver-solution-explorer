
--************************************ A B A I X O		S E G U E	  D E S E N V O L V I M E N T O ******************************************

---------------------------------------------------------------------------------------------------------------------------------------------
--Primeiramente, deve ser criada uma tabela para armazenar o log das querys mais demoradas que rodam no nosso banco de dados. 
--Deve-se escolher a database adequada do seu ambiente para armazenar essa tabela. 
--Também criei um índice nessa tabela para efetuar as buscas pela data em que a query rodou.
---------------------------------------------------------------------------------------------------------------------------------------------
use Maintenance
go

CREATE TABLE Management.TraceSlowQuery(		 
    TextData VARCHAR(MAX) NULL,
    NTUserName VARCHAR(128) NULL,
    HostName VARCHAR(128) NULL,
    ApplicationName VARCHAR(128) NULL,
    LoginName VARCHAR(128) NULL,
    SPID INT NULL,
    Duration NUMERIC(15, 2) NULL,		-- no insert já vai ficar em segundos
    StartTime DATETIME NULL,
    EndTime DATETIME NULL,
    Reads bigint,
    Writes bigint,
    CPU bigint,
    ServerName VARCHAR(128) NULL,
    DataBaseName VARCHAR(128),
    RowCounts bigint,
    SessionLoginName VARCHAR(128)
	)

-- Para realizar as querys de busca pela data que a query rodou.   

CREATE CLUSTERED INDEX SK01_Traces on Management.TraceSlowQuery(StartTime) with(FILLFACTOR=95)


-- foi necessário alteração devido ao estouro para o tipo de dados int, assim falhava a tarefa.
--ALTER TABLE TraceSlowQuery alter column Reads bigint

--ALTER TABLE TraceSlowQuery alter column Writes bigint

--ALTER TABLE TraceSlowQuery alter column CPU bigint

--ALTER TABLE TraceSlowQuery alter column RowCounts bigint

---------------------------------------------------------------------------------------------------------------------------------------------
--Em seguida, criaremos uma procedure para criar o arquivo de trace que ficará rodando em backgroud no servidor.
--Nessa procedure é criado um trace com a procedure sp_trace_create, onde especificamos o caminho que esse trace será armazenado.
--Com a procedure sp_trace_setevent, nós definimos quais os eventos que nosso trace pegará.

--A lista completa com todos os eventos pode ser encontrada no books online pesquisando pela procedure sp_trace_setevent.
--Em seguida é realizado o filtro na coluna 13(Duration) para retornar apenas os 
--valores maiores ou iguais a 3 segundos. Segue abaixo o script dessa procedure.
---------------------------------------------------------------------------------------------------------------------------------------------
USE Maintenance
GO

CREATE OR ALTER PROCEDURE Management.[sp_CreateTrace]
WITH ENCRYPTION
AS
BEGIN
    declare @rc int, 
			@TraceID INT,	
			@maxfilesize bigint, 
			@on bit, 
			@intfilter int, 
			@bigintfilter bigint
	
	BEGIN TRY
		BEGIN TRANSACTION
			select @on = 1, @maxfilesize = 100000
			-- Criação do trace
			exec @rc = sp_trace_create @TraceID output, 0, N'C:\DBACravil\Trace\Querys_Demoradas', @maxfilesize, NULL		-- nome gerado -> Querys_Demoradas
			if (@rc != 0) goto error
			exec sp_trace_setevent @TraceID, 10, 1, @on 
			exec sp_trace_setevent @TraceID, 10, 6, @on 
			exec sp_trace_setevent @TraceID, 10, 8, @on 
			exec sp_trace_setevent @TraceID, 10, 10, @on
			exec sp_trace_setevent @TraceID, 10, 11, @on
			exec sp_trace_setevent @TraceID, 10, 12, @on
			exec sp_trace_setevent @TraceID, 10, 13, @on
			exec sp_trace_setevent @TraceID, 10, 14, @on
			exec sp_trace_setevent @TraceID, 10, 15, @on
			exec sp_trace_setevent @TraceID, 10, 16, @on
			exec sp_trace_setevent @TraceID, 10, 17, @on
			exec sp_trace_setevent @TraceID, 10, 18, @on
			exec sp_trace_setevent @TraceID, 10, 26, @on
			exec sp_trace_setevent @TraceID, 10, 35, @on
			exec sp_trace_setevent @TraceID, 10, 40, @on
			exec sp_trace_setevent @TraceID, 10, 48, @on
			exec sp_trace_setevent @TraceID, 10, 64, @on
			exec sp_trace_setevent @TraceID, 12, 1,  @on
			exec sp_trace_setevent @TraceID, 12, 6,  @on
			exec sp_trace_setevent @TraceID, 12, 8,  @on
			exec sp_trace_setevent @TraceID, 12, 10, @on
			exec sp_trace_setevent @TraceID, 12, 11, @on
			exec sp_trace_setevent @TraceID, 12, 12, @on
			exec sp_trace_setevent @TraceID, 12, 13, @on
			exec sp_trace_setevent @TraceID, 12, 14, @on
			exec sp_trace_setevent @TraceID, 12, 15, @on
			exec sp_trace_setevent @TraceID, 12, 16, @on
			exec sp_trace_setevent @TraceID, 12, 17, @on
			exec sp_trace_setevent @TraceID, 12, 18, @on
			exec sp_trace_setevent @TraceID, 12, 26, @on
			exec sp_trace_setevent @TraceID, 12, 35, @on
			exec sp_trace_setevent @TraceID, 12, 40, @on
			exec sp_trace_setevent @TraceID, 12, 48, @on
			exec sp_trace_setevent @TraceID, 12, 64, @on

			set @bigintfilter = 20000000								-- valor de microssegundos que dá 20 segundos
			exec sp_trace_setfilter @TraceID, 13, 0, 4, @bigintfilter

			-- Set the trace status to start
			exec sp_trace_setstatus @TraceID, 1
			goto finish
			error:
			select ErrorCode=@rc
			finish:
		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION

		DECLARE @corpoFalha varchar(max)
		      , @subject VARCHAR(100)			-- assunto
		      , @recipients VARCHAR(100);		-- destinatário				
		SET @subject = 'Falha na Job TI_CapturaRequisicoesLentas';
		SET @recipients = 'robson@cravil.com.br';
		SET @corpoFalha = '	
			<html>
			<head>
			<meta http-equiv=Content-Type content=text/html; charset=windows-1252>
			</head>
			<body>
			<div align=left>'
		SELECT @corpoFalha = @corpoFalha + '
		<table border=0 cellpadding=0 cellspacing=0 width=402 style=border-collapse: collapse;table-layout:fixed;width:1000pt;font-family:Arial;font-size:14px>
			 <tr height=20 style=height:20.0pt>
			  <td height=20 colspan=7 style=height:20.0pt;text-align:left><b>Falha na Procedure [sp_CreateTrace]:<b> <br>
			  </td>
			 </tr>
			 <tr height=20 style=height:20.0pt>
			  <td height=20 colspan=7 style=height:20.0pt;text-align:left>
				  <br> [ERROR NUMBER] - '+ cast(ERROR_NUMBER() as varchar(10)) + '
				  <br>				  
				  <br> [LINE] - '+ cast(ERROR_LINE() as varchar(10)) + '
				  <br>
				  <br> [MESSAGE] - '+  ERROR_MESSAGE() + '
			   </td>
			  </tr>
		</table>'

		SELECT @corpoFalha = @corpoFalha + 
			'</div>
			</body>
			</html>'

		EXEC [msdb].[dbo].[sp_send_dbmail]
				@recipients = @recipients,
				@subject = @subject,
				@profile_name = 'Cravil_ERP',
				@body = @corpoFalha,
				@body_format = 'HTML';

	END CATCH
END
GO


---------------------------------------------------------------------------------------------------------------------------------------------
-- Agora vamos rodar nossa procedure para criar o trace.
---------------------------------------------------------------------------------------------------------------------------------------------
use Maintenance
go
exec Management.sp_CreateTrace


---------------------------------------------------------------------------------------------------------------------------------------------
-- Para conferir o trace criado, basta executar a query abaixo.
---------------------------------------------------------------------------------------------------------------------------------------------
SELECT *
FROM :: fn_trace_getinfo(default)
where cast(value as varchar(100)) = N'C:\DBACravil\Trace\Querys_Demoradas.trc'


---------------------------------------------------------------------------------------------------------------------------------------------
-- Conferindo todos os dados que foram armazenados no trace.
---------------------------------------------------------------------------------------------------------------------------------------------
Select Textdata, NTUserName, HostName, ApplicationName, LoginName, SPID, cast(Duration /1000/1000.00 as numeric(15,2)) as DurationSegundos,
	   Duration as DurationMicrossegundos, Starttime, EndTime, Reads, writes, CPU, Servername, DatabaseName, rowcounts, SessionLoginName
FROM :: fn_trace_gettable(N'C:\DBACravil\Trace\Querys_Demoradas.trc', default)
where Duration is not null
order by Starttime


---------------------------------------------------------------------------------------------------------------------------------------------
--	Você deve criar um Job no Management Studio com o nome “DBA - Trace Querys Demoradas” e esse job deve possuir 3 steps.
--	STEP 1- No primeiro Step devemos parar o trace momentaneamente para enviar todo o seu resultado para a tabela de log. 
--  Nesse step, você deve selecionar a database em que vc criou a tabela que armazenará o trace e incluir a query abaixo no step.
/*############## AINDA EXISTE O PROBLEMA DE QUANDO EXISTE MAIS DE UM VALOR NULO NO CAMPO VALUE DO fn_trace_getinfo ##############*/
---------------------------------------------------------------------------------------------------------------------------------------------
Declare @Trace_Id int
if ((select COUNT(*) from :: fn_trace_getinfo(default) where value is null) > 1
	and (select COUNT(value) FROM :: fn_trace_getinfo(default) where cast(value as varchar(100)) = N'C:\DBACravil\Trace\Querys_Demoradas.trc') = 0)
	begin
		print 'Sem definição'
		return
	end
	else
	if ((select COUNT(*) from :: fn_trace_getinfo(default) where value is null) > 1 
		and (select COUNT(value) FROM :: fn_trace_getinfo(default) where cast(value as varchar(100)) = N'C:\DBACravil\Trace\Querys_Demoradas.trc') = 1 )
	 begin 
		print 'Tem mais de um nulo mas tem o trace'
		set @Trace_Id = (select traceid FROM :: fn_trace_getinfo(default) where cast(value as varchar(100)) = N'C:\DBACravil\Trace\Querys_Demoradas.trc')	
	 end
	 else if ((select COUNT(*) from :: fn_trace_getinfo(default) where value is null) = 1 
			  and (select COUNT(value) FROM :: fn_trace_getinfo(default) where cast(value as varchar(100)) = N'C:\DBACravil\Trace\Querys_Demoradas.trc') = 1)
		   begin
			print 'Tem nulo e tem nome do trace'
			set @Trace_Id = (select traceid FROM :: fn_trace_getinfo(default) where cast(value as varchar(100)) = N'C:\DBACravil\Trace\Querys_Demoradas.trc')		
		   end
		   else if ((select COUNT(*) from :: fn_trace_getinfo(default) where value is null) = 1 
					 and (select COUNT(value) FROM :: fn_trace_getinfo(default) where cast(value as varchar(100)) = N'C:\DBACravil\Trace\Querys_Demoradas.trc') = 0)
					begin 
						print 'Tem nulo e ta sem nome do trace'
						set @Trace_Id = (select traceid FROM :: fn_trace_getinfo(default) where value is null)				
					end
					else if (select COUNT(*) from :: fn_trace_getinfo(default) where value is null) = 0
							 and (select COUNT(value) FROM :: fn_trace_getinfo(default) where cast(value as varchar(100)) = N'C:\DBACravil\Trace\Querys_Demoradas.trc') = 1
							 begin
								print 'Não tem nulo e tem nome do trace'
								set @Trace_Id = (select traceid FROM :: fn_trace_getinfo(default) where cast(value as varchar(100)) = N'C:\DBACravil\Trace\Querys_Demoradas.trc')						
							 end

exec sp_trace_setstatus  @traceid = @Trace_Id,  @status = 0  -- Interrompe o rastreamento especificado.
exec sp_trace_setstatus  @traceid = @Trace_Id,  @status = 2  -- Fecha o rastreamento especificado e exclui sua definição do servidor.

Insert Into Management.TraceSlowQuery(Textdata, NTUserName, HostName, ApplicationName, LoginName, SPID, Duration, Starttime,
    EndTime, Reads,writes, CPU, Servername, DatabaseName, rowcounts, SessionLoginName)
Select Textdata, NTUserName, HostName, ApplicationName, LoginName, SPID, cast(Duration /1000/1000.00 as numeric(15,2)) Duration, Starttime,
    EndTime, Reads,writes, CPU, Servername, DatabaseName, rowcounts, SessionLoginName
FROM :: fn_trace_gettable(N'C:\DBACravil\Trace\Querys_Demoradas.trc', default)
where Duration is not null
order by Starttime


---------------------------------------------------------------------------------------------------------------------------------------------
--	STEP 2 - Agora que os dados do trace já foram armazenados na tabela, deve-se excluir o arquivo de trace para que um novo seja criado. 
--  Isso pode ser realizado executando o comando: 
---------------------------------------------------------------------------------------------------------------------------------------------
--	del C:\Trace\Querys_Demoradas.trc /Q

---------------------------------------------------------------------------------------------------------------------------------------------
--	STEP 3 - Esse passo deve apenas recriar o trace. Similar ao step 1, 
-- você deve selecionar a database em que vc criou a procedure e rodar a query abaixo:
---------------------------------------------------------------------------------------------------------------------------------------------
use Maintenance
go
exec Management.sp_CreateTrace


--********************************************************** D E F I N I Ç Õ E S ****************************************************************************


---------------------------------------------------------------------------------------------------------------------------------------------
--	sp_trace_create:
---------------------------------------------------------------------------------------------------------------------------------------------
--Essa procedure cria um trace. 
--Ela funciona como o botão New Trace do aplicativo SQL Profiler. 
--Ao ser executada, uma variável output é retornada com o id interno do trace


---------------------------------------------------------------------------------------------------------------------------------------------
--	sp_trace_setevent:
---------------------------------------------------------------------------------------------------------------------------------------------
--Essa procedure funciona como o EventSelection. 
--Executando-a e informando o traceid retornado na execução da sp_trace_create podemos configurar o que coletaremos. 
--Devemos informar o id do trace, o id do evento que coletaremos, 
--o id das informações que serão retornadas e a informação 0 ou 1 para ativar ou desativar aquele registro. 
--Por exemplo, a execução:

--EXEC sp_trace_setevent @TraceID, 10, 1, 1 - TextData

--Coleta as chamadas das procedures, independente de onde venham as chamadas. 
--Exemplificando, se existe uma chamada de procedure com a execução exec procedure @param=1. 
--Esse texto é o que será registrado nessa opção. Isso por que o id 10 diz respeito ao RPC:Completed e o id 1 à informação TextData


---------------------------------------------------------------------------------------------------------------------------------------------
--	sp_trace_setfilter:
---------------------------------------------------------------------------------------------------------------------------------------------
--Funciona como a seleção de filtros da aplicação SQL Profiler. 
--Aqui podemos informar qual o filtro e qual o parâmetro utilizado para sua execução. 
--Além do id do trace, informamos na execução o id do filtro e o parâmetro de seleção. 
--No exemplo:

--EXEC sp_trace_setfilter @TraceID, 13, 0, 4, '500000'

--adicionamos um filtro de tempo de execução (id 13) que seja maior ou igual (id 4) do que meio segundo (500000 microssegundos).


---------------------------------------------------------------------------------------------------------------------------------------------
--	sp_trace_setstatus:
---------------------------------------------------------------------------------------------------------------------------------------------
--A mais simples do conjunto até agora, funciona como o botão Run do SQL Profiler. 
--Informando o id do trace e a opção 1, ela inicia a coleta. 
--Ao ser executada, ela retorna outro número, que é o que precisamos para que a coleta seja finalizada. 
--Ao executar a mesma procedure com a opção 0, o trace é finalizado.
--Exemplos com o uso de sp_trace_setstatus,

  -- Inicia o trace 
  EXEC sp_trace_setstatus @TraceID, 1
   
  -- Para o Trace
  EXEC sp_trace_setstatus @TraceID, 0
