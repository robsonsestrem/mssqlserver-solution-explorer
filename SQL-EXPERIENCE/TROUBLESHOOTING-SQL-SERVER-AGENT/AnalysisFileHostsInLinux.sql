/*
 *
    OBJETIVO: Vivencia com troubleshooting do SQL Server Agent no Linux (Amazon Linux 2),
    cobrindo incidente real envolvendo resolucao de hostname/hosts,
    limite de 15 caracteres e validacao pos-correcao.
    Inclui comandos Linux (como comentarios) e comandos T-SQL executaveis.

    PROJETO: mssqlserver-solution-explorer

    REFERENCIAS DE URL:
    * https://learn.microsoft.com/en-us/sql/linux/install-upgrade/setup-sql-agent?view=sql-server-ver16&tabs=rhel
    * https://learn.microsoft.com/en-us/sql/linux/sql-server-linux-known-issues?view=sql-server-ver17
    * https://learn.microsoft.com/en-us/sql/database-engine/install-windows/rename-a-computer-that-hosts-a-stand-alone-instance-of-sql-server?view=sql-server-ver17
    * https://www.pythian.com/blog/sql-server-agent-on-linux-not-starting-try-this-10-step-troubleshooting-guide
    * https://stackoverflow.com/questions/56739546/sql-server-agent-service-could-not-be-started
    * https://www.sqlservercentral.com/forums/topic/sql-server-agent-not-running-on-linux
    * https://www.mssqltips.com/sqlservertip/5471/how-to-change-sql-server-instance-name-running-on-a-linux-server/
    * https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/hostname-types.html
*
*/
/* ============================================================
   RESOLUCAO DE INCIDENTE: SQL SERVER AGENT NO LINUX
   Amazon Linux 2 | SQL Server 2017 (RTM-CU31-GDR) 14.0.3465.1
   Web Edition (64-bit)
   ============================================================

   --------------------------------------------------------------
   1. CENARIO E CONTEXTO
   -------------------------------------------------------------

   Ambiente:
   - Sistema Operacional: Amazon Linux 2 (ID_LIKE="centos rhel fedora")
   - SQL Server: 2017 RTM-CU31-GDR (KB5029376) - 14.0.3465.1
   - Edicao: Web Edition (64-bit) on Linux (Amazon Linux 2)
   - Repositorio: /etc/yum.repos.d/mssql-server.repo
     baseurl=https://packages.microsoft.com/rhel/7/mssql-server-2017/   

   A partir do CU4, o SQL Server Agent NAO e mais um pacote separado
   (mssql-server-agent). Ele vem embutido no pacote mssql-server e
   apenas fica desabilitado por padrao.

   Referencia oficial:
   https://learn.microsoft.com/en-us/sql/linux/install-upgrade/setup-sql-agent?view=sql-server-ver16&tabs=rhel

   Citacao da Microsoft:
   "Starting with SQL Server 2017 (14.x) CU 4, SQL Server Agent is
   included with the mssql-server package and is disabled by default."

   --------------------------------------------------------------
   2. SINTOMAS OBSERVADOS
   -------------------------------------------------------------

   - As Jobs do SQL Server Agent pararam de funcionar.
   - O servico mssql-server estava ativo (running).
   - O parametro sqlagent.enabled estava configurado como true.
   - O arquivo /var/opt/mssql/log/SQLAgent.out NAO EXISTIA.
   - O comando grep -i "agent" no errorlog retornava vazio.
   - A DMV sys.dm_server_services retornava status_desc = 'Not Running'
     para o SQL Server Agent.
   - A tentativa de iniciar Jobs retornava:
     "SQLServerAgent is not currently running so it cannot be notified
     of this action. (Microsoft SQL Server, Error: 22022)"

   --------------------------------------------------------------
   3. INVESTIGACAO REALIZADA
   -------------------------------------------------------------

   3.1. Verificacao da configuracao mssql-conf:

   Comando Linux:
   # sudo cat /var/opt/mssql/mssql.conf
   # Resultado: [sqlagent] enabled = true  (configuracao OK)

   3.2. Verificacao do hostname:

   Comando Linux:
   # hostname
   # Servidor 1 (yourserver01): hostname = yourserver01 (12 chars, OK)
   # Servidor 2 (yourserver02): hostname = yourserver02.dominio.local
   #   (26 chars - EXCEDE O LIMITE DE 15 CARACTERES)

   Referencia oficial - Known Issues:
   https://learn.microsoft.com/en-us/sql/linux/sql-server-linux-known-issues?view=sql-server-ver17

   Citacao da Microsoft:
   "The length of the hostname where SQL Server is installed needs to
   be 15 characters or less."
   Resolucao: "Change the name in /etc/hostname to a value 15 characters
   long or less."

   3.3. Verificacao do /etc/hosts (CAUSA RAIZ NO SERVIDOR 1):

   Comando Linux:
   # cat /etc/hosts
   # Conteudo encontrado no servidor yourserver01:
   #   127.0.0.1   localhost localhost.localdomain ...
   #   ::1         localhost6 ...
   #   8.8.8.8 yourserver01

   PROBLEMA IDENTIFICADO:
   O IP 8.8.8.8 e um IP PUBLICO, nao privado.
   O comando hostname -I retornou: 192.168.0.40  10.241.73.99
   Nenhum desses IPs privados correspondia ao /etc/hosts.

   O SQL Server Agent resolve "yourserver01" -> encontra 8.8.8.8
   -> tenta conectar em 8.8.8.8:1433 -> FALHA, pois instancias EC2
   da AWS nao conseguem conectar ao proprio IP publico (NAT hairpinning/
   loopback nao implementado pela AWS para auto-conexao).

   Isso explica por que o SQLAgent.out nem chegava a ser criado: o Agent
   tentava iniciar, falhava na conexao TCP com (local),1433 resolvido
   para o IP publico, e terminava silenciosamente.

   Caso identico documentado por outro usuario em Amazon Linux 2:
   https://stackoverflow.com/questions/56739546/sql-server-agent-service-could-not-be-started

   Citacao do usuario theofilis (StackOverflow):
   "I found from logs that the SQL Agent was trying to connect with
   instance '(local),1433' in /var/opt/mssql/log/sqlagent.out.
   I'm using Amazon Linux 2 with Sql Server 2017 updated."

   Outro caso similar em AWS EC2 (Ubuntu):
   https://www.sqlservercentral.com/forums/topic/sql-server-agent-not-running-on-linux

   Citacao do usuario mTBCent (SQLServerCentral):
   "SQLServerAgent could not be started (reason: Unable to connect to
   server '(local),1433'; SQLServerAgent cannot start)"

   Referencia AWS - Hostname types e comportamento de DNS:
   https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/hostname-types.html

   --------------------------------------------------------------
   4. CAUSA RAIZ
   -------------------------------------------------------------

   Servidor 1 (yourserver01):
   - Causa: IP publico no /etc/hosts mapeado para o hostname.
   - Impacto: O SQL Server Agent nao conseguia estabelecer conexao
     TCP consigo mesmo via (local),1433, pois a AWS nao implementa
     NAT loopback para auto-conexao via IP publico.
   - O arquivo SQLAgent.out nao era criado porque o processo do Agent
     abortava antes de qualquer log.

   Servidor 2 (yourserver02):
   - Causa 1: Hostname com 30 caracteres (limite e 15).
   - Causa 2: Mesmo problema potencial de /etc/hosts (IP incorreto).
   - Impacto: O Agent nao inicia por falha de resolucao de nome e
     por violacao do limite de caracteres de hostname.

   Guia de troubleshooting de referencia (Pythian):
   https://www.pythian.com/blog/sql-server-agent-on-linux-not-starting-try-this-10-step-troubleshooting-guide
*/

/* ============================================================
   5. CORRECAO APLICADA - SERVIDOR 1 (yourserver01)
   Correcao do /etc/hosts com IP privado correto
   ============================================================

   --------------------------------------------------------------
   5.1. IDENTIFICAR O IP PRIVADO CORRETO DA INTERFACE eth0
   -------------------------------------------------------------

   Comando Linux:
   # ip -4 addr show eth0
   # Resultado esperado: inet 192.168.0.40/24 brd 192.168.0.255 scope global eth0
   # O IP que aparecer em eth0 e o que deve ser usado no /etc/hosts.

   Alternativa:
   # hostname -I
   # Retorna todos os IPs privados: 192.168.0.40  10.241.73.99
   # Escolher o que corresponde a eth0.

   --------------------------------------------------------------
   5.2. VERIFICAR EM QUAL IP O SQL SERVER ESTA ESCUTANDO
   -------------------------------------------------------------

   Comando Linux:
   # sudo cat /var/opt/mssql/log/errorlog | grep -i "listening"

   Se o SQL Server estiver escutando em 0.0.0.0:1433 (todas as
   interfaces), qualquer IP privado funciona. Se estiver em um IP
   especifico, use aquele.

   --------------------------------------------------------------
   5.3. CORRIGIR O /etc/hosts
   -------------------------------------------------------------

   Comando Linux:
   # sudo nano /etc/hosts

   ANTES (incorreto):
   127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
   ::1         localhost localhost6 localhost6.localdomain6
   8.8.8.8 yourserver01

   DEPOIS (correto):
   127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
   ::1         localhost localhost6 localhost6.localdomain6
   192.168.0.40   yourserver01

   A linha com o IP publico (8.8.8.8) DEVE ser removida
   completamente. O SQL Server Agent precisa resolver o hostname
   para um IP privado local alcancavel por TCP na porta 1433.

   NUNCA use 127.0.0.1 para o hostname do SQL Server. Use o IP
   privado real da interface de rede primaria.

   --------------------------------------------------------------
   5.4. VALIDAR A RESOLUCAO DE NOME
   -------------------------------------------------------------

   Comando Linux:
   # ping -c 1 yourserver01
   # Esperado: PING yourserver01 (192.168.0.40) ... 64 bytes from yourserver01

   Comando Linux:
   # nc -zv 192.168.0.40 1433
   # Esperado: Connection to 192.168.0.40 1433 port [tcp/ms-sql-s] succeeded!

   --------------------------------------------------------------
   5.5. REINICIAR O SQL SERVER
   -------------------------------------------------------------

   Comando Linux:
   # sudo systemctl stop mssql-server
   # sleep 5
   # sudo systemctl start mssql-server
   # sleep 10
   # sudo systemctl status mssql-server
   # Esperado: active (running)
*/

/* ============================================================
   6. CORRECAO APLICADA - SERVIDOR 2 (yourserver02)
   Correcao de hostname + /etc/hosts
   ============================================================

   --------------------------------------------------------------
   6.1. PARAR O SQL SERVER
   -------------------------------------------------------------

   Comando Linux:
   # sudo systemctl stop mssql-server

   --------------------------------------------------------------
   6.2. ALTERAR O HOSTNAME NO SO (hostnamectl)
   -------------------------------------------------------------

   O hostname yourserver02.dominio.local tem 26 caracteres.
   O nome curto yourserver02 tem 12 caracteres - dentro do limite.

   Comando Linux:
   # sudo hostnamectl set-hostname yourserver02

   Verificar:
   # hostname
   # Esperado: yourserver02

   --------------------------------------------------------------
   6.3. ATUALIZAR O /etc/hosts
   -------------------------------------------------------------

   Comando Linux:
   # sudo nano /etc/hosts

   ANTES (incorreto):
   127.0.0.1   localhost localhost.localdomain ...
   ::1         localhost6 ...
   192.168.0.45   yourserver02.dominio.local

   DEPOIS (correto):
   127.0.0.1   localhost localhost.localdomain ...
   ::1         localhost6 ...
   192.168.0.45   yourserver02

   Usar o IP privado real da instancia (o mesmo que ja estava no
   arquivo), nunca o IP publico.

   --------------------------------------------------------------
   6.4. GARANTIR PERMISSOES
   -------------------------------------------------------------

   Comando Linux:
   # sudo chown -R mssql:mssql /var/opt/mssql

   --------------------------------------------------------------
   6.5. INICIAR O SQL SERVER
   -------------------------------------------------------------

   Comando Linux:
   # sudo systemctl start mssql-server
   # sleep 10
   # sudo systemctl status mssql-server

   --------------------------------------------------------------
   6.6. ATUALIZAR METADADOS DO SQL SERVER (sp_dropserver/sp_addserver)

   O SQL Server armazena o nome do servidor em sys.servers. Apos
   mudar o hostname do SO, o @@SERVERNAME ainda retorna o nome
   antigo. E preciso alinhar com sp_dropserver e sp_addserver.

   Referencia oficial da Microsoft:
   https://learn.microsoft.com/en-us/sql/database-engine/install-windows/rename-a-computer-that-hosts-a-stand-alone-instance-of-sql-server?view=sql-server-ver17

   Procedimento documentado para Linux:
   https://www.mssqltips.com/sqlservertip/5471/how-to-change-sql-server-instance-name-running-on-a-linux-server/
   ============================================================
*/

