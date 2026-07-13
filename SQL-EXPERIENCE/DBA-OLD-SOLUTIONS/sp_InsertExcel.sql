USE YOUR_DATABASE
GO

CREATE PROCEDURE Management.[sp_InsertExcel](
    @Caminho VARCHAR(MAX), 
    @Aba varchar(200), 
    @Tabela varchar(200), 
    @Colunas varchar(MAX)
)
WITH ENCRYPTION
AS
BEGIN

    IF (@Colunas = '*')
    BEGIN
    
        SELECT 
            @Colunas = isnull(nullif(@Colunas,'*') + ',','') + b.name
        FROM 
            sysobjects a WITH(NOLOCK)
            JOIN syscolumns b WITH(NOLOCK) ON a.id = b.id
        WHERE 
            a.xtype = 'U'
            AND a.name = @Tabela
    END		
    

    DECLARE @Exec VARCHAR(MAX)

    SET @Exec = 'INSERT INTO OPENROWSET (''Microsoft.ACE.OLEDB.12.0'', ''Excel 12.0;Database='
        + @Caminho
        + ';'',	''SELECT '
        + @Colunas
        + ' FROM ['
        + @Aba
        + '$]'') '
        + 'SELECT '
        + @Colunas
        + ' FROM '
        + @Tabela

    EXEC(@Exec) 
END


--------------------------------------------------------------------------------------------------------
-- Como usar [sp_InsertExcel]
--------------------------------------------------------------------------------------------------------
use IntegraTICravil
go

create table #temp(nome varchar(20), email varchar(20))
insert into #temp
values('debora', 'debora@gmail.com')

exec Management.sp_InsertExcel
@Caminho = 'C:\SQLImportExport\Teste.xlsx', -- Diret�rio
@Aba = 'pla01',								-- Guia do excel (sifr�o j� est� na procedure)
@Tabela = '#temp',							-- Tabela de origen dos dados para inserir
@Colunas = '*'								-- Tentado colunas da tabela de origem ou da planilha e n�o foi... 

drop table #temp
