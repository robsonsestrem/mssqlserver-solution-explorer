--------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- ROTINA PARA INTEGRAÇÃO
--------------------------------------------------------------------------------------------------------------------------------------------------------------------
DECLARE @datainicio datetime = dateadd(DAY,-1,cast(floor(cast(getdate()as float))as datetime))
DECLARE @datafinal datetime = dateadd(MILLISECOND,+997,dateadd(SECOND,+59,dateadd(MINUTE,+59,dateadd(HOUR,+23,dateadd(DAY,-1,cast(floor(cast(getdate()as float))as datetime))))))

SET NOCOUNT ON

INSERT INTO IntegraTICravil.Bi.HistoricoCMV(  DataIntegracao, CodigoFilial, DataEmissao, NumeroControle, NumeroNFe, Operacao
											, CodigoProduto, SequenciaItemNota, Codigofamilia, CodigoGrupo, CodigoSubgrupo
											, CustoMercadoriaVendida, Setor, Secao, CentroCusto, Quantidade, Margem, Peso, Estoque, CustoTotal )
							(
								SELECT GETDATE(), x.Filial, x.Emissao, x.NumControle,x.NF,x.Op, x.Item
									, x.SequenciaItem, x.CodFamilia, x.CodGrupo, x.CodSubgrupo
									, cmv.CustoMedioUnitario, x.Setor, x.Secao, x.CentroCusto
									, x.Qtdade, x.Margem, x.Peso, cmv.Estoque, cmv.CustoTotal
								FROM GesCooper90.dbo.vw_MovimentacaoReceita AS x WITH(NOLOCK)
								CROSS APPLY
								GesCooper90.dbo.GetCustoMercadoria(x.Filial, x.Item, x.Emissao) AS cmv 
								WHERE x.Emissao between @datainicio and @datafinal
							)			


--------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- CRIAÇÃO DA TABELA COM CHAVE COMPOSTA PARA RELACIONAMENTO COM A VIEW 'vw_Movimentacao_Receita'
--------------------------------------------------------------------------------------------------------------------------------------------------------------------
use IntegraTICravil
go

create table Bi.HistoricoCMV 
(

DataIntegracao datetime not null,
CodigoFilial smallint not null,
DataEmissao datetime not null,
NumeroControle int not null,
NumeroNFe int not null,
Operacao smallint not null,
CodigoProduto int not null,
SequenciaItemNota int not null, 
Codigofamilia int not null,
CodigoGrupo int not null,
CodigoSubgrupo int not null,
CustoMercadoriaVendida decimal(14,4) not null,
Setor smallint not null,
Secao smallint not null,
CentroCusto int not null,
Quantidade money NULL,
Margem smallmoney NULL,
Peso money NULL,
Estoque money NULL,
CustoTotal numeric(14, 4) NULL,

constraint PK_CMVTransf primary key (CodigoFilial, DataEmissao, NumeroControle, SequenciaItemNota)

)

-- VERIFICAR MAIS ÍNDICES




