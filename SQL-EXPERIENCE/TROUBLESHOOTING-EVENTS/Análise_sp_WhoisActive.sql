-- https://www.dirceuresende.com/blog/sql-server-utilizando-a-sp-whoisactive-para-identificar-locks-blocks-queries-lentas-queries-em-execucao-e-muito-mais/

-- DEFAULT
USE YOUR_DATABASE
GO
execute Management.sp_WhoIsActive 

/**************************************	 OUTROS PAR�METROS	**************************************************************************************************/
-- O par�metro @show_own_spid (BIT) determina se a pr�pria sess�o que est� executando a procedure far� parte do resultado final que ser� mostrado na tela. 
-- O valor padr�o � 0 (zero), fazendo com que a pr�pria sess�o n�o seja mostrada por padr�o.
execute Management.sp_WhoIsActive 
@show_own_spid = 1 -- mostrar minha sess�o

------------------------------------------------------------------------------------------------------------------------------------------------------------
-- mostrar as sess�es internas do sql server
execute Management.sp_WhoIsActive
@show_system_spids = 1 

------------------------------------------------------------------------------------------------------------------------------------------------------------
-- mostra todas as sess�es inativas
execute Management.sp_WhoIsActive
@show_sleeping_spids = 1 

------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Consultando ajuda - traz Informa��es sobre o criador da SP; Descri��o dos par�metros da chamada da SP; Descri��o das colunas retornadas pela SP
execute Management.sp_WhoIsActive 
@help = 1


/**************************************	EXECU��ES FILTRADAS	**************************************************************************************************/
execute Management.sp_WhoIsActive
  @filter = '57'
 ,@filter_type = 'session'
execute Management.sp_WhoIsActive
  @filter = 'cravil\ti-02'
 ,@filter_type = 'login'
execute Management.sp_WhoIsActive
  @filter = 'net'
 ,@filter_type = 'program'
execute Management.sp_WhoIsActive
  @filter = 'YOUR_DATABASE'
 ,@filter_type = 'database'
execute Management.sp_WhoIsActive
  @filter = 'W-NFE'
 ,@filter_type = 'host'


/*******************************  INFORMA��ES ADICIONAIS	**************************************************************************************************/
-- Por padr�o, a instru��o SQL que � retornada em forma de XML na coluna sql_text � apenas o trecho (batch) que est� sendo processado no momento. 
-- Ao utilizar esse par�metro, podemos observar todo o conte�do do batch que foi enviado para o processamento do SQL Server.
execute Management.sp_WhoIsActive
@get_full_inner_text = 1  -- bem necess�rio pra pegar query inteira


------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Ao utilizar esse par�metro com o valor 1, ser� gerado uma demonstra��o do plano de execu��o da query atual de cada sess�o retornada por essa SP. 
-- Utilizando o valor 2 nesse par�metro, � gerado o plano de execu��o de toda a query das sess�es. Ao clicar no XML do ResultSet,
-- o Management Studio j� exibe o plano de execu��o dessa query.
execute Management.sp_WhoIsActive
@get_plans = 2	-- bem necess�rio 1 OU 2


------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Esse par�metro � parecido com o @get_full_inner_text, mas ao inv�s de substituir o valor da coluna sql_text, ele mant�m essa coluna com seu valor 
-- padr�o (apenas o trecho em execu��o) e adiciona uma nova coluna chamada sql_command, que cont�m toda a query que a sess�o est� executando. 
-- Desta forma, temos as duas vis�es.
execute Management.sp_WhoIsActive
@get_outer_command = 1	 -- bem necess�rio


------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Com a utiliza��o desse par�metro, podemos visualizar a quantidade e volume de dados escritos no log de transa��o de cada sess�o.
execute Management.sp_WhoIsActive
@get_transaction_info = 1


------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Par�metro muito interessante para an�lise de performance, o @get_task_info permite visualizar mais informa��es sobre as sess�es em execu��o. 
-- Ao utilizar o valor 1, podemos visualizar o maiores eventos de wait (que n�o sejam CXPACKET). Ao utilizar o par�metro 2, vamos visualizar o modo completo, 
-- que inclu� as colunas:
-- PHISICIAL_IO: Mostra o n�meros de leituras/escritas (I/O) f�sicas no disco
-- CONTEXT_SWITCHES: Mostra o n�mero de mudan�as de contextos para a conex�o ativa. 
-- Uma mudan�a de contexto � quando o kernel do SO troca o processador de uma thread por outra (ex: uma thread de maior prioridade). Esse indicador � muito 
-- importante para identificar se um processo est� usando mais o CPU que os outros processos e impedindo que eles cheguem ao processador. Um �ndice muito alto, 
-- quer dizer que est� ocorrendo muita concorr�ncia no processador e ele pode estar sobrecarregado. Um n�mero baixo, significa que algum processo est� alocando
-- mais o CPU que deveria, gerando muito tempo de wait (e provavelmente sess�es com status Pending e Runnable). Os valores esperados devem ser algo abaixo 
-- de 2.000 trocas por processador/segundo (alguns DBA�s consideram um valor abaixo de 5.000 como aceit�vel). Valores muito altos podem estar sendo causados
-- por falhas de aloca��o de mem�ria f�sica (RAM). Um outro poss�vel agravante � a tecnologia Intel� Hyper-Threading, que em alguns casos pode causar muitas 
-- mudan�as de contexto por conta da simula��o de n�cleos virtuais. Caso esteja passando por esse problema, um bom teste � desativar esse recurso na 
-- placa m�e do servidor e realizar testes de performance.
-- TASKS: Numero de tarefas sendo utilizadas pela execu��o atual.
execute Management.sp_WhoIsActive
@get_task_info = 2 -- 1 OU 2(melhor)


------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Par�metro muito �til para manuten��o e identifica��o de locks na inst�ncia. Quando ativado, mostra os objetos reservados de cada requisi��o, 
-- bem como o tipo de bloqueio solicitado pela sess�o.
execute Management.sp_WhoIsActive
@get_locks = 1


------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Com a utiliza��o desse par�metro, surge uma nova coluna no resultado final (dd hh:mm:ss.mss (avg)). Essa coluna mostra o tempo m�dio de execu��o 
-- da query atual em execu��o por cada sess�o. 
execute Management.sp_WhoIsActive
@get_avg_time = 1


------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Com a utiliza��o desse par�metro, ser� criada uma nova coluna no resultado final chamada �additional_info�, que � um XML com v�rias informa��es e 
-- defini��es de comandos SET de cada sess�o.
-- Caso voc� utilize os par�metros @get_task_info = 2 e @get_additional_info = 1 e houver um lock em alguma sess�o, o XML da coluna �additional_info� 
-- dessa sess�o que est� em lock ter� um n� chamado block_info com as informa��es do block:
execute Management.sp_WhoIsActive
@get_additional_info = 1


------------------------------------------------------------------------------------------------------------------------------------------------------------
-- O @find_block_leaders quando ativado, permite analisar cada sess�o e contar quantas outras sess�es est�o em lock 
-- aguardando a libera��o de objetos por essa sess�o.
execute Management.sp_WhoIsActive
@find_block_leaders = 1


------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Al�m de muito completa, essa SP nos permite personalizar de v�rias formas o resultado final e sa�da gerada. Vou demonstrar agora, como fazer isso.
execute Management.sp_WhoIsActive
@output_column_list = '[session_id], [login_name], [program_name], [hostname], [sql_text]'


------------------------------------------------------------------------------------------------------------------------------------------------------------
-- esse par�metro serve para ordenar os resultados conforme a sua necessidade, onde voc� escolher quais colunas utilizar 
-- para a ordena��o e qual o crit�rio (asc ou desc).
execute Management.sp_WhoIsActive
@sort_order = '[session_id] asc'


------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Esse par�metro serve para alterar a forma de visualiza��o de algumas colunas para um modo mais �humano� de leitura. Com o valor 1, o formato de 
-- sa�da utilizar� fontes de comprimento vari�vel. Com o valor 2, o formato de sa�da utilizar� fontes de comprimento fixo.
execute Management.sp_WhoIsActive
@format_output = 0 -- 0 ou 1 ou 2, com o zero muda o xml para texto normal


------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Esses par�metros em conjunto servem para gerar o script de cria��o do resultado da SP. O par�metro @return_schema quando setado para 1, 
-- ao inv�s de retornar o resultado da execu��o, gera o script de CREATE TABLE do resultado. Esse script deve ser lido utilizando uma vari�vel de 
-- OUTPUT no par�metro @schema, conforme demonstrado abaixo:
declare @saida varchar(max)

execute Management.sp_WhoIsActive
 @return_schema = 1 -- bit
,@get_plans = 2
,@format_output = 0
,@schema = @saida output

select @saida

------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Ele serve para inserir o resultado da execu��o da SP em uma tabela f�sica, onde podemos armazenar de hist�rico e consultar quando quisermos.
IF (OBJECT_ID('tempdb.dbo.#whoisactive') IS NOT NULL) DROP TABLE #whoisactive
CREATE TABLE tempdb.dbo.#whoisactive ( 
[dd hh:mm:ss.mss] varchar(8000) NULL,[session_id] smallint NOT NULL,[sql_text] xml NULL,
[login_name] nvarchar(128) NOT NULL,[wait_info] nvarchar(4000) NULL,[CPU] varchar(30) NULL,[tempdb_allocations] varchar(30) NULL,
[tempdb_current] varchar(30) NULL,[blocking_session_id] smallint NULL,[reads] varchar(30) NULL,[writes] varchar(30) NULL,
[physical_reads] varchar(30) NULL,[used_memory] varchar(30) NULL,[status] varchar(30) NOT NULL,[open_tran_count] varchar(30) NULL,
[percent_complete] varchar(30) NULL,[host_name] nvarchar(128) NULL,[database_name] nvarchar(128) NULL,[program_name] nvarchar(128) NULL,
[start_time] datetime NOT NULL,[login_time] datetime NULL,[request_id] int NULL,[collection_time] datetime NOT NULL
)
execute Management.sp_WhoIsActive
@destination_table = 'tempdb.dbo.#whoisactive'

SELECT * FROM #whoisactive


