-------------------------------------------------------------------------------------------------------------------------------
--Try to rewrite your Cursor based TSQLs with correlated subqueries
-------------------------------------------------------------------------------------------------------------------------------

--You can rewrite your Cursor based code with a correlated subquery.

--Generally, you use a Cursor to obtain a result set, and then process each row one by one to formulate the desired result. 
--This kind of processing could be replaced with a correlated subquery (in most cases).

--What is a correlated subquery?

--A correlated subquery is a subquery where the outer query has to be executed first, and then for each row in the outer query, 
--the inner query is executed. That means, before executing the inner query for a particular row, 
--the outer query has to be processed for that particular row (and hence, the inner query is correlated with the outer one).

--Take a look at the following query again (you've seen this already). This is a correlated subquery:


SELECT E.Name AS [Employee Name],
	(SELECT Name FROM Employee WHERE ID = E.MgrID) AS [Manager Name] -- CORRELAÇÃO
FROM Employee E

--Let's break this query. The outer query is:

SELECT E.Name as [Employee Name] FROM Employee E  -- EXTERNA

--And, the inner query is:

SELECT Name FROM Employee WHERE ID = E.MgrID	  -- INTERNA


--Note the WHERE clause in the inner query (ID = E.MgrID). 
--In order to execute this inner query, the query processing engine needs E.MgrID to be available already. 
--So, to determine each row in the overall result set, the query is processed in the following way:

--Obtain the Name column value (as Employee Name) and MgrID column value from the Employee table.
--Obtain the Name column value (as Manager Name) from the Employee table where ID = MgrID.
--As you can see, to determine each row in the result set, the SQL execution engine has to execute two different SQLs. 
--But, the execution of this query is far more optimized compared to the UDF and Cursor based query, 
--because in the subquery way, the SQL Server decides the optimized and best way to 
--implement the inner query in its execution plan (like deciding the best algorithm for implementation of a join), 
--and hence the query executes faster (Set based approach).

--However, if you already have some complex processing logic implemented using a Cursor that is executed 
--for each row in the result set, and if you think that implementing the same logic using a Set based 
--approach is hard or near to impossible, you can follow this approach: