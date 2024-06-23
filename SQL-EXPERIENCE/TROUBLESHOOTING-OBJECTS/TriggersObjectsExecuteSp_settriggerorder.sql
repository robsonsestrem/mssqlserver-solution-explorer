SELECT 
     sysobjects.name AS trigger_name 
    ,USER_NAME(sysobjects.uid) AS trigger_owner 
    ,s.name AS table_schema 
    ,OBJECT_NAME(parent_obj) AS table_name 
    ,OBJECTPROPERTY( id, 'ExecIsUpdateTrigger') AS isupdate 
    ,OBJECTPROPERTY( id, 'ExecIsDeleteTrigger') AS isdelete 
    ,OBJECTPROPERTY( id, 'ExecIsInsertTrigger') AS isinsert 
    ,OBJECTPROPERTY( id, 'ExecIsAfterTrigger') AS isafter 
    ,OBJECTPROPERTY( id, 'ExecIsInsteadOfTrigger') AS isinsteadof 
    ,OBJECTPROPERTY( id, 'ExecIsTriggerDisabled') AS [disabled]     
FROM sysobjects 
INNER JOIN sysusers ON sysobjects.uid = sysusers.uid 
INNER JOIN sys.tables t ON sysobjects.parent_obj = t.object_id 
INNER JOIN sys.schemas s  ON t.schema_id = s.schema_id 
WHERE sysobjects.type = 'TR'
AND OBJECT_NAME(parent_obj) IN ('ACSPA', 'AVALS', 'CNSUL', 'MEDRS', 'PSSOA', 'QTNAV', 'RESPC')
--AND sysobjects.name NOT LIKE '%audit%'
--AND sysobjects.name LIKE 'TG_NAO_INSERIR_RESPC_AVALS_APOS_CONCLUIDA'
ORDER BY OBJECT_NAME(parent_obj)


----------------------------------------------------------------------------
-- ordem execução de triggers
----------------------------------------------------------------------------
SELECT 
    t.name AS trigger_name,
    te.type_desc AS event_type,
    t.is_disabled,
    te.is_first,
    te.is_last,
    t.create_date
FROM 
    sys.triggers t
INNER JOIN 
    sys.trigger_events te ON t.object_id = te.object_id
WHERE 
    t.parent_id IN ( OBJECT_ID('ACSPA'), OBJECT_ID('AVALS'), OBJECT_ID('QTNAV'), OBJECT_ID('CNSUL'), OBJECT_ID('MEDRS'), OBJECT_ID('PSSOA'), OBJECT_ID('RESPC'))
ORDER BY t.name 
    --t.create_date ASC;

---------------------------------------------------------------------------------------------------
SELECT
    sys.TABLES.name,
    sys.TRIGGERS.name,
    sys.TRIGGER_EVENTS.type,
    sys.TRIGGER_EVENTS.TYPE_DESC,
    IS_FIRST,
    IS_LAST,
    sys.TRIGGERS.CREATE_DATE,
    sys.TRIGGERS.MODIFY_DATE
FROM sys.TRIGGERS
INNER JOIN sys.TRIGGER_EVENTS
    ON sys.TRIGGER_EVENTS.object_id = sys.TRIGGERS.object_id
INNER JOIN sys.TABLES
    ON sys.TABLES.object_id = sys.TRIGGERS.PARENT_ID
WHERE sys.TABLES.name IN ('ACSPA', 'AVALS', 'CNSUL', 'MEDRS', 'PSSOA', 'QTNAV', 'RESPC')
ORDER BY sys.TABLES.name

--ACSPA
--AVALS
--CNSUL
--MEDRS
--PSSOA
--QTNAV
--RESPC

/*
 * FONTES
 * https://www.sqlshack.com/triggers-in-sql-server/
 * https://www.c-sharpcorner.com/UploadFile/f0b2ed/execution-order-of-trigger-in-sql/
 * https://learn.microsoft.com/pt-br/sql/relational-databases/system-stored-procedures/sp-settriggerorder-transact-sql?view=sql-server-ver16
 */


/************************** Tratamento na ordem de execução de triggers para evitar operações desnecessárias **************************/
----------------------------------------------------------------------------------------------------------------------------------------
-- Ordem de execução para tabela ACSPA
----------------------------------------------------------------------------------------------------------------------------------------
IF EXISTS (SELECT 1 FROM sys.objects WHERE type = 'TR' AND name = 'TGR_EXCLUI_ACSPA_INFO')
BEGIN 
    EXEC sys.sp_settriggerorder  @triggername ='TGR_EXCLUI_ACSPA_INFO', @order = 'FIRST', @stmttype =  'DELETE';    
END
GO


----------------------------------------------------------------------------------------------------------------------------------------
-- Ordem de execução para tabela AVALS
----------------------------------------------------------------------------------------------------------------------------------------
IF EXISTS (SELECT 1 FROM sys.objects WHERE type = 'TR' AND name = 'TG_NAO_DELETAR_AVALS_CONCLUIDAS')
BEGIN 
    EXEC sys.sp_settriggerorder  @triggername ='TG_NAO_DELETAR_AVALS_CONCLUIDAS', @order = 'FIRST', @stmttype =  'DELETE';    
END
GO


----------------------------------------------------------------------------------------------------------------------------------------
-- Ordem de execução para tabela CNSUL
----------------------------------------------------------------------------------------------------------------------------------------
IF EXISTS (SELECT 1 FROM sys.objects WHERE type = 'TR' AND name = 'TG_VERIFICA_AGENDAMENTO_NA_DATA')
BEGIN 
    EXEC sys.sp_settriggerorder  @triggername ='TG_VERIFICA_AGENDAMENTO_NA_DATA', @order = 'FIRST', @stmttype =  'INSERT';    
END
GO

IF EXISTS (SELECT 1 FROM sys.objects WHERE type = 'TR' AND name = 'TG_AUDIT_CNSUL')
BEGIN 
    EXEC sys.sp_settriggerorder  @triggername ='TG_AUDIT_CNSUL', @order = 'LAST', @stmttype =  'INSERT';
    
    EXEC sys.sp_settriggerorder  @triggername ='TG_AUDIT_CNSUL', @order = 'LAST', @stmttype =  'UPDATE';
    
    EXEC sys.sp_settriggerorder  @triggername ='TG_AUDIT_CNSUL', @order = 'LAST', @stmttype =  'DELETE';
END
GO


----------------------------------------------------------------------------------------------------------------------------------------
-- Ordem de execução para tabela MEDRS
----------------------------------------------------------------------------------------------------------------------------------------
IF EXISTS (SELECT 1 FROM sys.objects WHERE type = 'TR' AND name = 'TGR_CALCULA_RISCO_MEDRS')
BEGIN 
    EXEC sys.sp_settriggerorder  @triggername ='TGR_CALCULA_RISCO_MEDRS', @order = 'LAST', @stmttype =  'INSERT';
    
    EXEC sys.sp_settriggerorder  @triggername ='TGR_CALCULA_RISCO_MEDRS', @order = 'LAST', @stmttype =  'UPDATE';
    
    EXEC sys.sp_settriggerorder  @triggername ='TGR_CALCULA_RISCO_MEDRS', @order = 'LAST', @stmttype =  'DELETE';
END
GO


----------------------------------------------------------------------------------------------------------------------------------------
-- Ordem de execução para tabela PSSOA
----------------------------------------------------------------------------------------------------------------------------------------
IF EXISTS (SELECT 1 FROM sys.objects WHERE type = 'TR' AND name = 'TR_U_PSSOA')
BEGIN 
    EXEC sys.sp_settriggerorder  @triggername ='TR_U_PSSOA', @order = 'FIRST', @stmttype =  'UPDATE';    
END
GO

IF EXISTS (SELECT 1 FROM sys.objects WHERE type = 'TR' AND name = 'TG_AUDIT_PSSOA')
BEGIN 
    EXEC sys.sp_settriggerorder  @triggername ='TG_AUDIT_PSSOA', @order = 'LAST', @stmttype =  'INSERT';
    
    EXEC sys.sp_settriggerorder  @triggername ='TG_AUDIT_PSSOA', @order = 'LAST', @stmttype =  'UPDATE';
    
    EXEC sys.sp_settriggerorder  @triggername ='TG_AUDIT_PSSOA', @order = 'LAST', @stmttype =  'DELETE';
END
GO


----------------------------------------------------------------------------------------------------------------------------------------
-- Ordem de execução para tabela QTNAV
----------------------------------------------------------------------------------------------------------------------------------------
IF EXISTS (SELECT 1 FROM sys.objects WHERE type = 'TR' AND name = 'TG_NAO_DELETAR_QTNAV_AVALS_CONCLUIDAS')
BEGIN 
    EXEC sys.sp_settriggerorder  @triggername ='TG_NAO_DELETAR_QTNAV_AVALS_CONCLUIDAS', @order = 'FIRST', @stmttype =  'DELETE';    
END
GO


----------------------------------------------------------------------------------------------------------------------------------------
-- Ordem de execução para tabela RESPC
----------------------------------------------------------------------------------------------------------------------------------------
IF EXISTS (SELECT 1 FROM sys.objects WHERE type = 'TR' AND name = 'TG_NAO_INSERIR_RESPC_AVALS_APOS_CONCLUIDA')
BEGIN 
    EXEC sys.sp_settriggerorder  @triggername ='TG_NAO_INSERIR_RESPC_AVALS_APOS_CONCLUIDA', @order = 'FIRST', @stmttype =  'INSERT';    
END
GO

IF EXISTS (SELECT 1 FROM sys.objects WHERE type = 'TR' AND name = 'TGR_CALCULA_RISCO_RESPC')
BEGIN 
    EXEC sys.sp_settriggerorder  @triggername ='TGR_CALCULA_RISCO_RESPC', @order = 'LAST', @stmttype =  'INSERT';
    
    EXEC sys.sp_settriggerorder  @triggername ='TGR_CALCULA_RISCO_RESPC', @order = 'LAST', @stmttype =  'UPDATE';
    
    EXEC sys.sp_settriggerorder  @triggername ='TGR_CALCULA_RISCO_RESPC', @order = 'LAST', @stmttype =  'DELETE';
END
GO


