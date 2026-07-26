/*
	OBJETIVO: Estimar o tempo de conclusão de processos SQL em execução que possuem
			  percentual de conclusão disponível (operações de backup, restore,
			  rebuild de índices, DBCC, etc.), exibindo métricas como tempo decorrido,
			  tipo de espera e o texto da instrução sendo executada.
	PROJETO: mssqlserver-solution-explorer

	REFERÊNCIAS E AUTORIA:
	Autor: Tim Ford
	Link original: http://sqlmag.com/database-administration/estimate-when-long-running-sql-processes-will-finish
*/
SET NOCOUNT ON;

-- ============================================================
-- Consulta principal: extrai dados de processos em execução
-- com percentual de conclusão disponível, estimando a hora
-- de término com base na velocidade média de processamento.
-- ============================================================
SELECT
      R.session_id
    , R.percent_complete
    , R.total_elapsed_time / 1000                                                      AS elapsed_seconds
    , R.wait_type
    , R.wait_time
    , R.last_wait_type
    , DATEADD
      (
          SECOND
        , 100 / ((R.percent_complete) / (R.total_elapsed_time / 1000))
        , R.start_time
      )                                                                                AS est_complete_time
    , ST.text                                                                          AS batch_text
    , CAST
      (
          SUBSTRING
          (
              ST.text
            , R.statement_start_offset / 2
            , (
                  (
                      CASE R.statement_end_offset
                          WHEN -1
                          THEN DATALENGTH(ST.text)
                          ELSE R.statement_end_offset
                      END - R.statement_start_offset
                  ) / 2
              )
          )
          AS VARCHAR(1024)
      )                                                                                AS statement_executing
FROM sys.dm_exec_requests                                                              AS R
CROSS APPLY sys.dm_exec_sql_text(R.sql_handle)                                         AS ST
WHERE R.percent_complete > 0
      AND R.session_id <> @@SPID;
