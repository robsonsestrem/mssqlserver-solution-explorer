/*
 *
    OBJETIVO: Validação de configurações do SQL Server Agent no Linux.
    
    PROJETO: mssqlserver-solution-explorer    
*
*/
/* -------------------------------------------------------------
   -- CHECKLIST DE VALIDAÇÃO
   -------------------------------------------------------------

   [ ] Servico mssql-server ativo
       Comando: sudo systemctl status mssql-server
       Esperado: active (running)

   [ ] Agent habilitado na configuracao
       Comando: sudo cat /var/opt/mssql/mssql.conf
       Esperado: [sqlagent] enabled = true

   [ ] Log do Agent criado e sem erros
       Comando: sudo cat /var/opt/mssql/log/SQLAgent.out
       Esperado: "SQLServerAgent service started successfully."

   [ ] Hostname <= 15 caracteres
       Comando: hostname
       Esperado: nome curto (ex: prd-yourserver01, prd-yourserver02)

   [ ] /etc/hosts com IP privado correto
       Comando: cat /etc/hosts
       Esperado: <IP_PRIVADO> <hostname_curto>

   [ ] Resolucao de nome funcionando
       Comando: ping -c 1 <hostname>
       Esperado: resolve para IP privado

   [ ] Porta 1433 acessivel localmente
       Comando: nc -zv <IP_PRIVADO> 1433
       Esperado: Connection succeeded

   [ ] Permissoes do diretorio mssql
       Comando: ls -la /var/opt/mssql/
       Esperado: owner mssql:mssql

   [ ] Agent XPs habilitadas
       SQL: EXEC sp_configure 'Agent XPs'
       Esperado: run_value = 1

   [ ] Agent Running via DMV
       SQL: SELECT status_desc FROM sys.dm_server_services
       Esperado: Running para SQL Server Agent

   [ ] @@SERVERNAME alinhado com hostname do SO
       SQL: SELECT @@SERVERNAME
       Esperado: igual ao retorno do comando "hostname"

   [ ] Job de teste executada com sucesso
       SQL: verificar sysjobhistory
       Esperado: run_status = 1 (Succeeded)

   [ ] Log de erros do SQL Server limpo
       Comando: sudo tail -30 /var/opt/mssql/log/errorlog
       Esperado: sem erros criticos
*/
