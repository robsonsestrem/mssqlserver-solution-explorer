--------------------------------------------------------------------------------------------------------------
-- Visualiza todas conex�es abertas
--------------------------------------------------------------------------------------------------------------
SELECT *
FROM master.dbo.sysprocesses
WHERE dbid = DB_ID('YOUR_DATABASE_homolog')


--------------------------------------------------------------------------------------------------------------
-- Quantidade de Conex�es por banco de dados
--------------------------------------------------------------------------------------------------------------
SELECT db_name(dbid) as Banco_de_Dados,
count(dbid) as Qtd_Conexoes
FROM sys.sysprocesses
WHERE --dbid > 50
db_name(dbid) = 'YOUR_DATABASE_homolog'
GROUP BY dbid, loginame -- agrupado por n�mero de sess�es abertas por usu�rio


/*************************************************************************************************************/
--------------------------------------------------------------------------------------------------------------
-- Colocando o Banco de Dados para Single_User 
--------------------------------------------------------------------------------------------------------------
Alter Database YOUR_DATABASE
Set Single_User With Rollback Immediate


--------------------------------------------------------------------------------------------------------------
-- Colocando o Banco de Dados que esta como Single_User para Multi_User
--------------------------------------------------------------------------------------------------------------
Alter Database YOUR_DATABASE
Set Multi_User With Rollback Immediate


/*************************************************************************************************************/


