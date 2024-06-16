-- https://www.dirceuresende.com/blog/sql-server-utilizando-a-sp-whoisactive-para-identificar-locks-blocks-queries-lentas-queries-em-execucao-e-muito-mais/

-- DEFAULT
USE Maintenance
GO
execute Management.sp_WhoIsActive 

/**************************************	 OUTROS PARÂMETROS	**************************************************************************************************/
-- O parâmetro @show_own_spid (BIT) determina se a própria sessão que está executando a procedure fará parte do resultado final que será mostrado na tela. 
-- O valor padrão é 0 (zero), fazendo com que a própria sessão não seja mostrada por padrão.
execute Management.sp_WhoIsActive 
@show_own_spid = 1 -- mostrar minha sessão

------------------------------------------------------------------------------------------------------------------------------------------------------------
-- mostrar as sessões internas do sql server
execute Management.sp_WhoIsActive
@show_system_spids = 1 

------------------------------------------------------------------------------------------------------------------------------------------------------------
-- mostra todas as sessões inativas
execute Management.sp_WhoIsActive
@show_sleeping_spids = 1 

------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Consultando ajuda - traz Informações sobre o criador da SP; Descrição dos parâmetros da chamada da SP; Descrição das colunas retornadas pela SP
execute Management.sp_WhoIsActive 
@help = 1


/**************************************	EXECUÇÕES FILTRADAS	**************************************************************************************************/
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
  @filter = 'gescooper90'
 ,@filter_type = 'database'
execute Management.sp_WhoIsActive
  @filter = 'W-NFE'
 ,@filter_type = 'host'


/*******************************  INFORMAÇÕES ADICIONAIS	**************************************************************************************************/
-- Por padrão, a instrução SQL que é retornada em forma de XML na coluna sql_text é apenas o trecho (batch) que está sendo processado no momento. 
-- Ao utilizar esse parâmetro, podemos observar todo o conteúdo do batch que foi enviado para o processamento do SQL Server.
execute Management.sp_WhoIsActive
@get_full_inner_text = 1  -- bem necessário pra pegar query inteira


------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Ao utilizar esse parâmetro com o valor 1, será gerado uma demonstração do plano de execução da query atual de cada sessão retornada por essa SP. 
-- Utilizando o valor 2 nesse parâmetro, é gerado o plano de execução de toda a query das sessões. Ao clicar no XML do ResultSet,
-- o Management Studio já exibe o plano de execução dessa query.
execute Management.sp_WhoIsActive
@get_plans = 2	-- bem necessário 1 OU 2


------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Esse parâmetro é parecido com o @get_full_inner_text, mas ao invés de substituir o valor da coluna sql_text, ele mantém essa coluna com seu valor 
-- padrão (apenas o trecho em execução) e adiciona uma nova coluna chamada sql_command, que contém toda a query que a sessão está executando. 
-- Desta forma, temos as duas visões.
execute Management.sp_WhoIsActive
@get_outer_command = 1	 -- bem necessário


------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Com a utilização desse parâmetro, podemos visualizar a quantidade e volume de dados escritos no log de transação de cada sessão.
execute Management.sp_WhoIsActive
@get_transaction_info = 1


------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Parâmetro muito interessante para análise de performance, o @get_task_info permite visualizar mais informações sobre as sessões em execução. 
-- Ao utilizar o valor 1, podemos visualizar o maiores eventos de wait (que não sejam CXPACKET). Ao utilizar o parâmetro 2, vamos visualizar o modo completo, 
-- que incluí as colunas:
-- PHISICIAL_IO: Mostra o números de leituras/escritas (I/O) físicas no disco
-- CONTEXT_SWITCHES: Mostra o número de mudanças de contextos para a conexão ativa. 
-- Uma mudança de contexto é quando o kernel do SO troca o processador de uma thread por outra (ex: uma thread de maior prioridade). Esse indicador é muito 
-- importante para identificar se um processo está usando mais o CPU que os outros processos e impedindo que eles cheguem ao processador. Um índice muito alto, 
-- quer dizer que está ocorrendo muita concorrência no processador e ele pode estar sobrecarregado. Um número baixo, significa que algum processo está alocando
-- mais o CPU que deveria, gerando muito tempo de wait (e provavelmente sessões com status Pending e Runnable). Os valores esperados devem ser algo abaixo 
-- de 2.000 trocas por processador/segundo (alguns DBA’s consideram um valor abaixo de 5.000 como aceitável). Valores muito altos podem estar sendo causados
-- por falhas de alocação de memória física (RAM). Um outro possível agravante é a tecnologia Intel® Hyper-Threading, que em alguns casos pode causar muitas 
-- mudanças de contexto por conta da simulação de núcleos virtuais. Caso esteja passando por esse problema, um bom teste é desativar esse recurso na 
-- placa mãe do servidor e realizar testes de performance.
-- TASKS: Numero de tarefas sendo utilizadas pela execução atual.
execute Management.sp_WhoIsActive
@get_task_info = 2 -- 1 OU 2(melhor)


------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Parâmetro muito útil para manutenção e identificação de locks na instância. Quando ativado, mostra os objetos reservados de cada requisição, 
-- bem como o tipo de bloqueio solicitado pela sessão.
execute Management.sp_WhoIsActive
@get_locks = 1


------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Com a utilização desse parâmetro, surge uma nova coluna no resultado final (dd hh:mm:ss.mss (avg)). Essa coluna mostra o tempo médio de execução 
-- da query atual em execução por cada sessão. 
execute Management.sp_WhoIsActive
@get_avg_time = 1


------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Com a utilização desse parâmetro, será criada uma nova coluna no resultado final chamada “additional_info”, que é um XML com várias informações e 
-- definições de comandos SET de cada sessão.
-- Caso você utilize os parâmetros @get_task_info = 2 e @get_additional_info = 1 e houver um lock em alguma sessão, o XML da coluna “additional_info” 
-- dessa sessão que está em lock terá um nó chamado block_info com as informações do block:
execute Management.sp_WhoIsActive
@get_additional_info = 1


------------------------------------------------------------------------------------------------------------------------------------------------------------
-- O @find_block_leaders quando ativado, permite analisar cada sessão e contar quantas outras sessões estão em lock 
-- aguardando a liberação de objetos por essa sessão.
execute Management.sp_WhoIsActive
@find_block_leaders = 1


------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Além de muito completa, essa SP nos permite personalizar de várias formas o resultado final e saída gerada. Vou demonstrar agora, como fazer isso.
execute Management.sp_WhoIsActive
@output_column_list = '[session_id], [login_name], [program_name], [hostname], [sql_text]'


------------------------------------------------------------------------------------------------------------------------------------------------------------
-- esse parâmetro serve para ordenar os resultados conforme a sua necessidade, onde você escolher quais colunas utilizar 
-- para a ordenação e qual o critério (asc ou desc).
execute Management.sp_WhoIsActive
@sort_order = '[session_id] asc'


------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Esse parâmetro serve para alterar a forma de visualização de algumas colunas para um modo mais “humano” de leitura. Com o valor 1, o formato de 
-- saída utilizará fontes de comprimento variável. Com o valor 2, o formato de saída utilizará fontes de comprimento fixo.
execute Management.sp_WhoIsActive
@format_output = 0 -- 0 ou 1 ou 2, com o zero muda o xml para texto normal


------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Esses parâmetros em conjunto servem para gerar o script de criação do resultado da SP. O parâmetro @return_schema quando setado para 1, 
-- ao invés de retornar o resultado da execução, gera o script de CREATE TABLE do resultado. Esse script deve ser lido utilizando uma variável de 
-- OUTPUT no parâmetro @schema, conforme demonstrado abaixo:
declare @saida varchar(max)

execute Management.sp_WhoIsActive
 @return_schema = 1 -- bit
,@get_plans = 2
,@format_output = 0
,@schema = @saida output

select @saida

------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Ele serve para inserir o resultado da execução da SP em uma tabela física, onde podemos armazenar de histórico e consultar quando quisermos.
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


