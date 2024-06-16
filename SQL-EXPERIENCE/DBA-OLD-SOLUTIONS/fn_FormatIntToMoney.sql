--------------------------------------------------------------
-- Referências - Júnior Galvão
-- Função condiciona valores para colocar até em planilhas
-- como um valor decimal válido
--------------------------------------------------------------
USE IntegraTICravil
GO
create or alter Function Erp.fn_FormatIntToMoney(@Valor Float) 
Returns varchar(30) 
with encryption
as
Begin

Return replace(replace(replace( convert(varchar, convert(money, @Valor), 1), '.', 'x'), 
                         ',', '.'), 'x', ',');
End;
Go
  


--Declare @Valores Table (ValorTotal float);
--Insert Into @Valores values (2042993.77), (1631290.05), (1020.44), (4332.30)

--SELECT Management.fn_FormatIntToMoney(ValorTotal) as formatado from @Valores;
--Go
