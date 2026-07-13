USE YOUR_DATABASE
GO

CREATE PROCEDURE Management.[sp_ImportExcel](
    @Caminho VARCHAR(5000), 
    @Aba VARCHAR(200), 
    @Colunas VARCHAR(5000)
)
WITH ENCRYPTION
AS
BEGIN

    DECLARE @Exec VARCHAR(MAX)

    SET @Exec = 'SELECT * from OPENROWSET (''Microsoft.ACE.OLEDB.12.0'', ''Excel 12.0;Database='
        + @Caminho
        + ';'',	''SELECT '
        + @Colunas
        + ' FROM ['
        + @Aba
        + '$]'') A'

    EXEC(@Exec)
 
END


--------------------------------------------------------------------------------------------------------
-- Como usar [sp_ImportExcel]
--------------------------------------------------------------------------------------------------------
--use IntegraTICravil
--go
--exec Management.sp_ImportExcel
--@Caminho = 'C:\SQLImportExport\Teste.xlsx', -- Diret�rio
--@Aba = 'pla02',								-- Guia do excel (sifr�o j� est� na procedure)
--@colunas = '*'								-- Campos