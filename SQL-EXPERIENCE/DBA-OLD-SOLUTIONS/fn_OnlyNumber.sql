USE IntegraTICravil
GO

CREATE FUNCTION dbaSystem.fn_OnlyNumber(@valor varchar(30))
RETURNS VARCHAR(30)
WITH ENCRYPTION
AS
BEGIN 	

	DECLARE @Result NVARCHAR(MAX)
	SET @Result = ''

	;WITH SPLIT AS
	(
	SELECT 1 AS ID, SUBSTRING(@valor, 1, 1) AS CH
	UNION ALL
	SELECT ID + 1, SUBSTRING(@valor, ID + 1, 1)
	FROM SPLIT
	WHERE ID < LEN(@valor)
	)
	SELECT @Result += CH	-- mesma lógica do java
	FROM SPLIT
	WHERE CH LIKE '[0-9]'
	OPTION (MAXRECURSION 0)

	RETURN @Result
END




--SELECT Management.fn_OnlyNumber('417.932.349-49')