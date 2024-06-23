-------------------------------------------------------------------------------------------------------------------------------
--Instead of a cursor, use a table variable to process the result set
-------------------------------------------------------------------------------------------------------------------------------

--What is a Table variable?
--In TSQL (since SQL Server 2000), a Table variable is a special kind of variable that resembles more or less an actual table. 
--But, the most important thing about a Table variable is, it resides in memory almost 100% of the time 
--(unless the Table variable itself is too large; in this case, the Table variable could reside in the tempdb database).

--Use of a Table variable is efficient (most of the time, in terms of memory and execution time) compared to 
--temporary tables because of the following reasons:
--Temporary tables reside in the tempdb database, and operating on temporary tables results in inter-DB communication. 
--This is bound to be slow. But, Table variables are mostly in memory variables, so I/O in Table variables is bound to be fast.
--Operating on temporary tables result in lots of disk activities and resource usage because:
--The temporary table has to be created
--Data has to be inserted on the temporary table
--Often, temporary table has to be joined with a physical table to obtain a result
--A lock has to be established on the temporary table while updating data on it
--Temporary table has to be dropped
--But, operating on table variables requires no locking on the resources. Moreover, data insertion on a 
--table variable is a lot faster than on a temporary table as no disk I/O and inter DB communication takes place. 
--Also, the table variable goes out of scope when the corresponding SQL block goes out of scope. Therefore, 
--table variables need not be dropped. All these make table variables an excellent choice for implementing faster TSQL.

--Well, now it's obvious that Table variables are better than the temporary tables in most cases. 
--But, can you use Table variables in place of Cursors?

--Yes, you can. Following is an example of processing a result set using a Table variable 
--(the SQL that uses the Cursor to process the result set is not included here, because I don't like you to learn Cursors.. ha ha)


-------------------------------------------------------------------------------------------------------------------------------
-- SOLUÇÃO COM MAIOR DESEMPENHO
-------------------------------------------------------------------------------------------------------------------------------

--Declare the Table variable 
DECLARE @Elements TABLE
(
    Number INT IDENTITY(1,1), --Auto incrementing Identity column
    ProductName VARCHAR(300)  --The string value
)

--Decalre a variable to remember the position of the current delimiter
DECLARE @N INT 

--Decalre a variable to remember the number of rows in the table
DECLARE @Count INT

--Populate the TABLE variable using some logic
INSERT INTO @Elements SELECT Name FROM dbo.Products

--Initialize the looper variable
SET @N = 1

--Determine the number of rows in the Table
SELECT @Count=max(Number) from @Elements

--A variable to hold the currently selected value from the table
DECLARE @CurrentValue varchar(300);

--Loop through until all row processing is done
WHILE @N <= @Count
BEGIN
    --Load current value from the Table
    SELECT @CurrentValue = ProductName FROM @Elements WHERE Number = @N
    --Process the current value
    print @CurrentValue
    --Increment loop counter
    SET @N = @N + 1;
END


--I can bet you will be surprised to see the performance benefits by replacing the Cursor based code that you might 
--have written with a Table variable based code.

--Please note that you still should try not to write TSQL using the Procedural approach
--(use of a Table variable is still a Procedural approach). 
--But, if for some reason you really need to write your own way of processing a result set, you can at least 
--use Table variables to avoid Cursors.
--Have fun writing Set based SQL. Enjoy!
