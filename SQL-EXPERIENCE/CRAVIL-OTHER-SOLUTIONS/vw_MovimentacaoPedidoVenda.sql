USE GesCooper90
GO

ALTER VIEW [dbo].[vw_MovimentacaoPedidoVenda]
AS
	SELECT 
	T1.[PvdNumero]					AS NumeroPedido
	, T1.[PvdFilCod]				AS FilialPedido
	, T1.NfFilCod					AS FilialCarga
	, T1.NfDatEmis					AS DataCarregamento
	, T4.PvdDatEmi					AS DataPedido
	, T4.PvdSituacao				AS SituaçãoPedido
	, T4.OpeEstCod					AS Operacao
	, T1.NfNumero					AS NumeroControle				
	, T4.PvdTraCod					AS Transacionador			
	, T1.[CarPedVenSequencial]		AS Carregamento
	, T1.[CarPedVenIteSequencial]	AS SequencialCarga
	, T2.[PvdProCod]				AS CodigoProduto
	, T3.[ProNom]					AS NomeProduto
	, T3.ProFamCod					AS Familia
	, T3.ProGrpCod					AS Grupo
	, T3.ProSubCod					AS Subgrupo
	, T3.[ProNomEmbEstoque]			AS Unidade
	, T3.[ProVlrPLiq]				AS PesoLiquido
	, T2.[PvdProVlr]				AS ValorUnitario
	, T2.PvdProVlrTabela			AS ValorTabela
	, T2.PvdProVlrMinimo			AS ValorMinimo
	, T1.[CarPedVenIteQuantidade]	AS Quantidade
	, T1.[CarPedVenIteVlrFrete]		AS ValorFrete
	, T1.[PvdIteSeq]				AS SequencialPedido
	, T5.CarNumDoc				    AS NumeroCarga	
	, T4.PvdForPag			
	, T4.PvdPagCod
	, T5.CarTraCod					AS CodigoTransportador
	, T5.CarTraMotCod			    AS CodigoMotorista
	, T5.CarTraMotNom				AS NomeMotorista
	FROM [CARPEDIDOVENDAITENS] T1 WITH (NOLOCK) 
	LEFT JOIN [PEDVENDASLEVEL1] T2 WITH (NOLOCK) 
		ON T2.[PvdFilCod] = T1.[PvdFilCod] 
		AND T2.[PvdNumero] = T1.[PvdNumero] 
		AND T2.[PvdIteSeq] = T1.[PvdIteSeq]
	LEFT JOIN [PRODUTOS] T3 WITH (NOLOCK) 
		ON T3.[ProCod] = T2.[PvdProCod] 
	INNER JOIN PEDVENDAS AS T4 
		ON T4.PvdFilCod = T2.PvdFilCod 
		AND T4.PvdNumero = T2.PvdNumero 		
	INNER JOIN CARGAS as T5 with (nolock )
		ON T5.CarPedVenSequencial = T1.CarPedVenSequencial				
	WHERE T5.CarSituacao = 3 -- Só trazer cargas processadas
GO