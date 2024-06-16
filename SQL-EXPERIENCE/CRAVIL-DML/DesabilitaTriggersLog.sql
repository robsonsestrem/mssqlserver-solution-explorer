USE GesCooper90
GO
------------------------------------------------------------------------------
-- Desabilita todas
------------------------------------------------------------------------------
ALTER TABLE CADUSUARIOS 
DISABLE TRIGGER tr_Cadusuarios_LogUID

ALTER TABLE PRODUTOS 
DISABLE TRIGGER tr_Produtos_LogUID

alter table PRODUTOSLEVEL4
disable trigger tr_Produtoslevel4_LogUID

alter table PROGUSULEVEL1
disable trigger tr_Progusulevel1_LogID

alter table TRANSACIONADORES
disable trigger tr_Transacionadores_LogUD 


------------------------------------------------------------------------------
-- Habilita todas
------------------------------------------------------------------------------
ALTER TABLE CADUSUARIOS 
ENABLE TRIGGER tr_Cadusuarios_LogUID

ALTER TABLE PRODUTOS 
ENABLE TRIGGER tr_Produtos_LogUID

alter table PRODUTOSLEVEL4
ENABLE trigger tr_Produtoslevel4_LogUID

alter table PROGUSULEVEL1
ENABLE trigger tr_Progusulevel1_LogID

alter table TRANSACIONADORES
ENABLE trigger tr_Transacionadores_LogUD 