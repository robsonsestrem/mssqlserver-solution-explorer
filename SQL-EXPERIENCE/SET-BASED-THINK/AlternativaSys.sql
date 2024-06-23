--------------------------------------------------------------------------------------------------------
--Uma alternativa ao uso de cursores
--------------------------------------------------------------------------------------------------------

--Ao falarmos de cursores muita gente arrepia os cabelos por achar complicado, por não entender, etc. 
--Porém, cursores são exaustivamente utilizados no desenvolvimento de 
--stored procedures e triggers de um modo geral. No entanto, o uso de cursores nesses objetos 
--acaba tornando o ambiente muito pesado, pois eles tomam boa parte dos recursos disponíveis 
--do servidor como disco, processador, dentre outros.
--Para alegria de muitos, existem os que não utilizam cursores de jeito nenhum, 
--fazendo manobras (verdadeiras obras primas do desenvolvimento) para que se tenha a mesma 
--situação como se estivesse usando cursores.
--Vamos aos exemplos:

DECLARE @processo smallint
DECLARE @nm_login NVARCHAR(256)
DECLARE cur_logins CURSOR FOR 
  SELECT sp.spid, 
         sp.uid 
  FROM   master..sysprocesses sp, 
         master..syslogins sl 
  WHERE  sp.sid = sl.sid 
         AND sp.uid != 0 
         AND sp.spid != @@spid 

OPEN cur_logins 

WHILE 0 = 0 
  BEGIN 
      FETCH cur_logins INTO @processo, @nm_login 

      IF @@FETCH_STATUS <> 0 
        BREAK 

      SELECT @processo as Processo, 
             @nm_login as login
  END 

CLOSE cur_logins 
DEALLOCATE cur_logins
GO;

 
--No exemplo acima, é declarado um cursor que lista todos os processos com logins ativos, 
--exceto o seu próprio, do servidor Sybase ASE. Depois disso é listado o número do processo 
--e o nome do login. Este é um exemplo básico para entendimento do desenvolvimento, 
--pois ao invés de listar o número do processo, poderia ser usado o comando para 
--bloqueio (sp_locklogin) ou encerramento (kill) do processo. 
--O mesmo código acima pode ser escrito sem o uso de cursor, conforme exemplo abaixo:

DECLARE @processo smallint
DECLARE @nm_login NVARCHAR(256)

SELECT sp.spid, 
       sp.uid 
INTO   #t_logins from master..sysprocesses sp, 
       master..syslogins sl 
	   where sp.sid = sl.sid 
	   and sp.uid != 0 
	   and sp.spid != @@spid 
WHILE 1=1 
BEGIN 
	set ROWCOUNT 1 
	select @processo = l.spid, @nm_login = suser_name(l.uid) 
	from #t_logins as l 
		if @@rowcount = 0 
		break 
	delete #t_logins 
	where spid = @processo 
	set ROWCOUNT 0 
	select @processo, @nm_login 
END

--O exemplo acima (sem cursor) tem o mesmo comportamento que o exemplo com cursor.
--Como vimos, existem várias maneiras de usar a mesma lógica de desenvolvimento sem ter que usar cursores. 
--Uma outra maneira possível de se fazer isso é usar tabelas temporárias com um campo 
--identity e varrer a tabela pelo campo identity (incremental).

