CREATE TABLE Employee
(
 EmpID int PRIMARY KEY,
 EmpName varchar (50) NOT NULL,
 Salary int NOT NULL,
 Address varchar (200) NOT NULL,
)
GO
INSERT INTO Employee(EmpID,EmpName,Salary,Address) VALUES(1,'Mohan',12000,'Noida')
INSERT INTO Employee(EmpID,EmpName,Salary,Address) VALUES(2,'Pavan',25000,'Delhi')
INSERT INTO Employee(EmpID,EmpName,Salary,Address) VALUES(3,'Amit',22000,'Dehradun')
INSERT INTO Employee(EmpID,EmpName,Salary,Address) VALUES(4,'Sonu',22000,'Noida')
INSERT INTO Employee(EmpID,EmpName,Salary,Address) VALUES(5,'Deepak',28000,'Gurgaon')
GO
SELECT * FROM Employee

CREATE OR ALTER PROCEDURE sp_testeLock @newValue int
AS 
BEGIN 

DECLARE @Id int
DECLARE @name varchar(50)
 DECLARE Dynamic_cur_empupdate CURSOR
DYNAMIC 
FOR 
SELECT EmpID,EmpName from Employee ORDER BY EmpName
OPEN Dynamic_cur_empupdate
IF @@CURSOR_ROWS > 0
 BEGIN 
 FETCH NEXT FROM Dynamic_cur_empupdate INTO @Id,@name
 WHILE @@Fetch_status = 0
 BEGIN
 IF @name='Mohan'
  BEGIN
    WAITFOR DELAY '00:00:30';
    Update Employee SET Salary = @newValue WHERE CURRENT OF Dynamic_cur_empupdate
  END
 FETCH NEXT FROM Dynamic_cur_empupdate INTO @Id,@name
 END
END
CLOSE Dynamic_cur_empupdate
DEALLOCATE Dynamic_cur_empupdate

END


--------------------------------------------------------------------------------------------------------------------------------------------------------
-- Executa procedure
--------------------------------------------------------------------------------------------------------------------------------------------------------
begin transaction
EXECUTE sp_testeLock 1500

commit transaction


select @@TRANCOUNT

--------------------------------------------------------------------------------------------------------------------------------------------------------
-- https://blog.sqlauthority.com/2015/01/10/sql-server-what-is-the-query-used-in-sp_cursorfetch-and-fetch-api_cursor/
-- Executa a coleta em outra sessão
--------------------------------------------------------------------------------------------------------------------------------------------------------
SELECT creation_time,
cursor_id,
c.session_id,
c.properties,
c.creation_time,
c.is_open,
SUBSTRING(st.TEXT, ( c.statement_start_offset / 2) + 1, (
( CASE c.statement_end_offset
WHEN -1 THEN DATALENGTH(st.TEXT)
ELSE c.statement_end_offset
END - c.statement_start_offset) / 2) + 1) AS statement_text
FROM   sys.dm_exec_cursors(0) AS c
JOIN sys.dm_exec_sessions AS s
ON c.session_id = s.session_id
CROSS apply sys.Dm_exec_sql_text(c.sql_handle) AS st