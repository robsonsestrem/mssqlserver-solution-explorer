USE P_HEALTHMAP_UNIMEDPA
GO

CREATE OR ALTER TRIGGER INDEX_PREVENTION
ON DATABASE
WITH ENCRYPTION
FOR CREATE_INDEX, ALTER_INDEX, DROP_INDEX
AS
BEGIN
    DECLARE @UserName NVARCHAR(100) = ORIGINAL_LOGIN();
        
    IF @UserName = 'healthmap'
    BEGIN      
        ;THROW 50000, 'User does not have permission to manipulate indexes, contact your database administrator.', 1;
    END
END
GO


-- Da de aplicar essa abordagem dentro do IF:
  --PRINT 'User does not have permission to manipulate indexes, contact your database administrator.';
  --ROLLBACK;
