-------------------------------------------------------------------------------------------------------------------------------------------
-- https://www.brentozar.com/blitz/configure-sql-server-alerts/
-- https://www.mssqltips.com/sqlservertip/2871/troubleshooting-and-fixing-sql-server-page-level-corruption/
-------------------------------------------------------------------------------------------------------------------------------------------
USE [msdb]
GO
EXEC msdb.dbo.sp_add_alert @name=N'Severity 016',
@message_id=0,
@severity=16,
@enabled=1,
@delay_between_responses=1,
@include_event_description_in=1,
@notification_message = 'Indica erros gerais que podem ser corrigidos pelo usuário. Contate o DBA.',
@job_id=N'00000000-0000-0000-0000-000000000000';
GO
EXEC msdb.dbo.sp_add_notification @alert_name=N'Severity 016', @operator_name=N'DBA_Alerts', @notification_method = 1;
GO

EXEC msdb.dbo.sp_add_alert @name=N'Severity 017',
@message_id=0,
@severity=17,
@enabled=1,
@delay_between_responses=1,
@include_event_description_in=1,
@notification_message ='Indica que a instrução fez o SQL Server ficar sem recursos (como memória, bloqueios ou espaço em disco para o banco de dados) ou exceder algum limite definido pelo administrador de sistema. Contate o DBA.',
@job_id=N'00000000-0000-0000-0000-000000000000';
GO
EXEC msdb.dbo.sp_add_notification @alert_name=N'Severity 017', @operator_name=N'DBA_Alerts_SetorTI', @notification_method = 1;
GO

EXEC msdb.dbo.sp_add_alert @name=N'Severity 018',
@message_id=0,
@severity=18,
@enabled=1,
@delay_between_responses=1,
@include_event_description_in=1,
@notification_message ='Indica um problema no software Mecanismo de Banco de Dados , mas a instrução conclui a execução e a conexão com a instância do Mecanismo de Banco de Dados é mantida. O administrador de sistema deve ser informado sempre que uma mensagem com nível de severidade 18 ocorrer. Contate o DBA.',
@job_id=N'00000000-0000-0000-0000-000000000000';
GO
EXEC msdb.dbo.sp_add_notification @alert_name=N'Severity 018', @operator_name=N'DBA_Alerts_SetorTI', @notification_method = 1;
GO

EXEC msdb.dbo.sp_add_alert @name=N'Severity 019',
@message_id=0,
@severity=19,
@enabled=1,
@delay_between_responses=1,
@include_event_description_in=1,
@notification_message ='Indica que um limite do Mecanismo de Banco de Dados não configurável foi excedido e que o processo em lotes atual foi encerrado. Contate o DBA.',
@job_id=N'00000000-0000-0000-0000-000000000000';
GO
EXEC msdb.dbo.sp_add_notification @alert_name=N'Severity 019', @operator_name=N'DBA_Alerts_SetorTI', @notification_method = 1;
GO

EXEC msdb.dbo.sp_add_alert @name=N'Severity 020',
@message_id=0,
@severity=20,
@enabled=1,
@delay_between_responses=1,
@include_event_description_in=1,
@notification_message ='Indica que uma instrução encontrou um problema. Como o problema afetou apenas a tarefa atual, é improvável que o banco de dados tenha sido danificado. Contate o DBA.',
@job_id=N'00000000-0000-0000-0000-000000000000';
GO
EXEC msdb.dbo.sp_add_notification @alert_name=N'Severity 020', @operator_name=N'DBA_Alerts_SetorTI', @notification_method = 1;
GO

EXEC msdb.dbo.sp_add_alert @name=N'Severity 021',
@message_id=0,
@severity=21,
@enabled=1,
@delay_between_responses=1,
@include_event_description_in=1,
@notification_message ='Indica que foi encontrado um problema que afeta todas as tarefas no banco de dados atual, mas é improvável que o banco de dados tenha sido danificado. Contate o DBA.',
@job_id=N'00000000-0000-0000-0000-000000000000';
GO
EXEC msdb.dbo.sp_add_notification @alert_name=N'Severity 021', @operator_name=N'DBA_Alerts_SetorTI', @notification_method = 1;
GO

EXEC msdb.dbo.sp_add_alert @name=N'Severity 022',
@message_id=0,
@severity=22,
@enabled=1,
@delay_between_responses=1,
@include_event_description_in=1,
@notification_message ='Indica que a tabela ou o índice especificado na mensagem foi danificado por um problema de software ou hardware. Contate o DBA.',
@job_id=N'00000000-0000-0000-0000-000000000000';
GO
EXEC msdb.dbo.sp_add_notification @alert_name=N'Severity 022', @operator_name=N'DBA_Alerts_SetorTI', @notification_method = 1;
GO

EXEC msdb.dbo.sp_add_alert @name=N'Severity 023',
@message_id=0,
@severity=23,
@enabled=1,
@delay_between_responses=1,
@include_event_description_in=1,
@notification_message ='Indica que a integridade do banco de dados inteiro está em risco por um problema de software ou hardware. Se um acontecer, execute o DBCC CHECKDB para determinar a extensão do dano. O problema pode ser apenas no cache e não no próprio disco. Contate o DBA.',
@job_id=N'00000000-0000-0000-0000-000000000000';
GO
EXEC msdb.dbo.sp_add_notification @alert_name=N'Severity 023', @operator_name=N'DBA_Alerts_SetorTI', @notification_method = 1;
GO

EXEC msdb.dbo.sp_add_alert @name=N'Severity 024',
@message_id=0,
@severity=24,
@enabled=1,
@delay_between_responses=1,
@include_event_description_in=1,
@notification_message ='Indica uma falha de mídia. O administrador de sistema pode ter que restaurar o banco de dados. Também pode ser necessário contatar o seu fornecedor de hardware. Contate o DBA.',
@job_id=N'00000000-0000-0000-0000-000000000000';
GO
EXEC msdb.dbo.sp_add_notification @alert_name=N'Severity 024', @operator_name=N'DBA_Alerts_SetorTI', @notification_method = 1;
GO

EXEC msdb.dbo.sp_add_alert @name=N'Severity 025',
@message_id=0,
@severity=25,
@enabled=1,
@delay_between_responses=1,
@include_event_description_in=1,
@notification_message ='Erro fatal do sistema. Pode estar relacionado a atualizações com falhas: algo impede que um dos scripts de atualização seja executado e um erro de gravidade 25 seja lançado. Contate o DBA.',
@job_id=N'00000000-0000-0000-0000-000000000000';
GO
EXEC msdb.dbo.sp_add_notification @alert_name=N'Severity 025', @operator_name=N'DBA_Alerts_SetorTI', @notification_method = 1;
GO

EXEC msdb.dbo.sp_add_alert @name=N'Error Number 823',
@message_id=823,
@severity=0,
@enabled=1,
@delay_between_responses=1,
@include_event_description_in=1,
@notification_message ='O problema é causado por APIs do Windows como ReadFile, WriteFileGather, ReadFileScatter e WriteFile, que são usadas para executar operações de E / S. A corrupção do banco de dados do servidor SQL também se torna a principal causa. Contate o DBA.',
@job_id=N'00000000-0000-0000-0000-000000000000'
GO
EXEC msdb.dbo.sp_add_notification @alert_name=N'Error Number 823', @operator_name=N'DBA_Alerts_SetorTI', @notification_method = 1;
GO

EXEC msdb.dbo.sp_add_alert @name=N'Error Number 824',
@message_id=824,
@severity=0,
@enabled=1,
@delay_between_responses=1,
@include_event_description_in=1,
@notification_message ='O SQL Server detectou um erro de E / S consistente em consistência lógica: incapaz de descriptografar a página por falta de DEK. Contate o DBA.',
@job_id=N'00000000-0000-0000-0000-000000000000'
GO
EXEC msdb.dbo.sp_add_notification @alert_name=N'Error Number 824', @operator_name=N'DBA_Alerts_SetorTI', @notification_method = 1;
GO

EXEC msdb.dbo.sp_add_alert @name=N'Error Number 825',
@message_id=825,
@severity=0,
@enabled=1,
@delay_between_responses=1,
@include_event_description_in=1,
@notification_message ='O SQL Server detectou um erro de E / S consistente em consistência lógica: checksum incorreto. Se de fato é apenas uma página afetada, você deve ser capaz de executar uma restauração no nível da página para recuperar o banco de dados. Detalhes completos estão aqui: http://www.sqlpassion.at/archive/2015/10/13/how-to-perform-a-page-level-restore-in-sql-server/  --> Contate o DBA.',
@job_id=N'00000000-0000-0000-0000-000000000000'
GO
EXEC msdb.dbo.sp_add_notification @alert_name=N'Error Number 825', @operator_name=N'DBA_Alerts_SetorTI', @notification_method = 1;
GO