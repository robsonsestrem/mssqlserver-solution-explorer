-----------------------------------------------------------------------------------------------------
-- Alterando nome da trigger e criptografando o código
-----------------------------------------------------------------------------------------------------
USE GesCooper90; 
GO 
IF OBJECT_ID(N'dbo.Trigger_HorarioVerao', N'TR') IS NOT NULL DROP TRIGGER dbo.Trigger_HorarioVerao; 
GO 
CREATE TRIGGER dbo.HorarioVerao 
ON FILIAIS
WITH ENCRYPTION AFTER INSERT, -- OPÇÃO ESTA QUE NÃO DEIXA MODIFICAR DEPOIS
UPDATE AS RAISERROR ('Notify Compensation', 16, 10); 
GO


-----------------------------------------------------------------------------------------------------
-- Habilita/Desabilita TRIGGER:
-----------------------------------------------------------------------------------------------------
alter table transacionadores
disable trigger tr_Transacionadores_LogUD    -- enable para habilitar novamente


-----------------------------------------------------------------------------------------------------
-- Apagar TRIGGER da tabela:
-----------------------------------------------------------------------------------------------------
drop trigger Trigger_HorarioVerao		-- deleta a trigger do banco


-----------------------------------------------------------------------------------------------------
-- Buscar todas os TRIGGERS do banco:
-----------------------------------------------------------------------------------------------------
USE GesCooper90
GO
select * from sys.triggers
where is_disabled = 0   -- verifica todas não desabilitadas, se for 1 traz só as desabilitadas


