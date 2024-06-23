-------------------------------------------------------------------------------------------------------------------------------
-- Requisições com maiores processos cumulativos na CPU
-------------------------------------------------------------------------------------------------------------------------------
USE master
GO
SELECT        spid,				-- ID da sessão do SQL Server 
			  status,
			  open_tran,
			  request_id,       -- ID da solicitação
              blocked,			-- ID da sessão de quem bloqueia 
			  waittime as temp, -- tempo de espera atual em milisegundos 
              Db_name(dbid) DB, -- ID do banco de dados usado atualmente pelo processo 
			  --CONVERT (TIME, DATEADD (MILLISECOND, cast(cpu as bigint) + 86400000,0), 114) as CPU_Time, -- sem conversão dava overflow			
			  cast(cpu as bigint) as CPU,		-- tempo de CPU cumulativo para o processo				-- no tipo de dados int
              physical_io,		-- IO cumulativas para o processo em disco 

              cast(memusage as bigint) as Paginas_Cache,	-- número de páginas no cache de procedimento que estão atualmente alocadas para este processo. 
															-- um número negativo indica que o processo está liberando memória alocada por outro processo 
              program_name,		-- aplicativo
              hostname,			-- PC que fez a requisição 
			  loginame,			-- usuário
              hostprocess		-- número de ID do processo da estação de trabalho 			
FROM   master..sysprocesses as s
WHERE  --status = 'sleeping'
--and open_tran = 0
 Db_name(dbid) IN ('d_healthmap_admhealthmap')
       --AND ( cpu > 0 OR physical_io > 0 ) 
	    --loginame = 'sa'	 
	   -- and  hostname in ('cti-000640')
	   -- and Db_name(dbid) = 'guru5'
	   -- and spid = 227
ORDER  BY status asc; 

--------------------------------------------------------------------------------------------------------------------------------
-- DBCC INPUTBUFFER - Exibe a última instrução enviada de um cliente a uma instância do Microsoft SQL Server
--------------------------------------------------------------------------------------------------------------------------------
DBCC inputbuffer(266)  -- o parâmetro é o spid que é a sessão do SQL-Server
-- retornará três colunas e na EventInfo terá o script da requisição
/*
Tipo de evento. Pode ser Evento RPC ou Evento Language.
A saída será No Event quando não for detectado nenhum último evento.
Para um EventType de RPC, EventInfo contém apenas o nome do procedimento. 
Para um EventType de Language, são exibidos apenas os primeiros 4000 caracteres do evento.
*/


--------------------------------------------------------------------------------------------------------------------------------
-- Converter os campos do tipo int para milissegundos
--------------------------------------------------------------------------------------------------------------------------------
-- Converter 5874502 Milisegundos para tempo
SELECT CONVERT(TIME, DATEADD(MILLISECOND, 5874502 + 86400000, 0), 114)

-- Converter 587 Segundos para tempo
SELECT CONVERT(TIME, DATEADD(SECOND, 587 + 86400000, 0), 114)

-- Converter 457 Minutos para tempo
SELECT CONVERT(TIME, DATEADD(MINUTE, 457 + 86400000, 0), 114)

-- Converter 5874502 Milisegundos para string
SELECT CONVERT(VARCHAR(12), DATEADD(MILLISECOND, 5874502 + 86400000, 0), 114)

--EX.:
-- CONVERT (TIME, DATEADD (MILLISECOND, waittime + 86400000, 0), 114) as temp,  

--------------------------------------------------------------------------------------------------------------------------------
-- coluna status	nchar(30) -> Status do ID do processo. Os valores possíveis são:
--------------------------------------------------------------------------------------------------------------------------------

 --dormant  (inativo) = SQL Server está redefinindo a sessão.

 --running (executando) = a sessão está executando um ou mais lotes. Quando são habilitados MARS (Vários Conjuntos de Resultados Ativos), uma sessão pode executar vários lotes. Para obter mais informações, consulte usando vários conjuntos de resultados ativos (. MARS &41;.

 --Background (plano de fundo) = a sessão está executando uma tarefa em segundo plano, como detecção de deadlock.

 --rollback (reversão) = a sessão tem uma reversão de transação em processo.

 --pending (pendente) = a sessão está aguardando um thread de trabalho se torne disponível.

 --runnable (executável) = a tarefa na sessão está na fila executável de um agendador enquanto aguarda para obter um quantum de tempo.

 --spinloop/sleeping = a tarefa na sessão está esperando um spinlock fique livre.

 --suspended (suspenso) = a sessão está aguardando um evento, como e/s, para concluir, em processo de retorno.