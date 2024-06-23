-------------------------------------------------------------------------------------------------------------------------------
--Use inline sub queries to replace User Defined Functions
-------------------------------------------------------------------------------------------------------------------------------

--Let's assume, for a self-referential table Employee(ID, Name,MgrID), 
--there is a query written in Procedural approach using a User Defined Function. 
--The query outputs employee names and corresponding manager names.
--Here is the query:


SELECT Name AS [Employee Name],
       dbo.fnGetManagerName(MgrID) as [Manager Name] 
FROM Employee

--Here, dbo.fnGetManagerName(MgrID) is a UDF that returns the manager's name 
--(which is nothing but another employee in the same Employee table) as follows:


CREATE FUNCTION [dbo].[fnGetManagerName](@ID int) 
RETURNS VARCHAR(50) AS
BEGIN
          --Declare the variable to hold result 
          DECLARE @ManagerName varchar(50)
          --Determine the Employee name by the given ID 
          SELECT @ManagerName = Name FROM Employee WHERE ID = @ID
          --Return the result
          RETURN @ManagerName
END
--The above Procedural SQL could be re-written using a sub query in Set based approach as follows:


-------------------------------------------------------------------------------------------------------------------------------
-- SOLUÇÃO COM MAIOR DESEMPENHO
-------------------------------------------------------------------------------------------------------------------------------

SELECT E.Name AS [Employee Name],
(
    SELECT Name FROM Employee WHERE ID = E.MgrID
) AS [Manager Name] 
FROM Employee E 

--In one of the projects I worked on, we had a slow performing Stored Procedure in a 
--moderate sized SQL Server 2000 database. The SP used to process around 20,000 records to produce a result set. 
--All we needed to optimize it was replace a UDF with an inline sub query 
--(because all other optimizations were done already). 
--Believe me, that turned down the total execution time from 90 long seconds to just 1 second!