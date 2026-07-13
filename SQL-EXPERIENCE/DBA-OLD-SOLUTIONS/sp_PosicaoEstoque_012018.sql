----------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Inser��o para 2018
----------------------------------------------------------------------------------------------------------------------------------------------------------------
use IntegraTICravil
go

create or alter procedure Bi.sp_PosicaoEstoque_012018
with encryption
as
begin 
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	declare @execucao datetime 
	declare @datalimite datetime

	-- dias a retroagir
	declare @limite smallint = -5

	-- coleta �ltima data processada e seta a pr�xima data pra ser calculada
	set @execucao = (select min(t1.[DataRotina]) -1 from IntegraTICravil.Bi.Execucao as t1
					 where t1.Descricao like '%HistoricoPosicaoEstoque%'
					 and year(t1.DataRotina) = 2018)

	-- seta um limite para o la�o while
	set @datalimite = dateadd(day, @limite, @execucao)

	while(@execucao > @datalimite)
	begin
	
		insert into IntegraTICravil.Bi.Execucao(DataInsercao, Descricao, DataRotina)
		values (GETDATE(), 'INSERT TABELA HistoricoPosicaoEstoque', @execucao)

		insert into IntegraTICravil.Bi.HistoricoPosicaoEstoque	
		(
		Filial , 
		NomeFilial , 
		DataEmissao ,
		CodigoProduto , 
		NomeProduto ,
		Codigofamilia ,
		NomeFamilia ,
		CodigoGrupo , 
		NomeGrupo ,
		CodigoSubgrupo ,
		NomeSubgrupo ,
		CustoMercadoriaVendida , 
		Estoque ,
		CustoTotal
		)   

		select distinct
		   t1.CodigoFilial as Filial
		   , t6.FilNom as Nome_Filial
		   , t1.DataEmissao as Posicao
		   , t1.CodigoProduto as Codigo_Produto
		   , t2.ProNom as Nome_Produto
		   , t1.Codigofamilia as Codigo_Familia
		   , t3.FamNom as Nome_Familia
		   , t1.CodigoGrupo as Codigo_Grupo
		   , t4.GrpNom as Nome_Grupo
		   , t1.CodigoSubgrupo as Codigo_Subgrupo
		   , t5.SubNom as Nome_Subgrupo   
		   , t1.CustoMercadoriaVendida
		   , t1.Estoque
		   , t1.CustoTotal
		 from IntegraTICravil.Bi.HistoricoCMV as t1 with(nolock) 
		 inner join YOUR_DATABASE.dbo.PRODUTOS as t2 with(nolock)
		 on t2.ProCod = t1.CodigoProduto
		 inner join YOUR_DATABASE.dbo.FAMILIAS as t3 with(nolock)
		 on t3.FamCod = t2.ProFamCod
		 inner join YOUR_DATABASE.dbo.GRUPOS as t4 with(nolock)
		 on t4.GrpCod = t2.ProGrpCod
		 and t4.FamCod = t2.ProFamCod
		 inner join YOUR_DATABASE.dbo.SUBGRUPOS as t5 with(nolock)
		 on t5.FamCod = t2.ProFamCod
		 and t5.GrpCod = t2.ProGrpCod
		 and t5.SubCod = t2.ProSubCod
		 inner join YOUR_DATABASE.dbo.FILIAIS as t6 with(nolock)
		 on t6.FilCod = t1.CodigoFilial
		 where t1.DataEmissao = @execucao

		 UNION ALL

			select x.FilCod, t7.FilNom, @execucao as Posicao, x.ProCod, t3.ProNom
				   , t4.FamCod, t4.FamNom, t5.GrpCod, t5.GrpNom, t6.SubCod, t6.SubNom
				   , t2.CustoMedioUnitario, t2.Estoque, t2.CustoTotal
			from(
				select t2.FilCod , t1.ProCod from YOUR_DATABASE.dbo.PRODUTOS as t1 with(nolock)
				cross apply YOUR_DATABASE.dbo.FILIAIS as t2 with(nolock)
				where t1.ProSituacao not like 'n'
				and t2.filflag2 = 0 -- filiais ativas
				and t2.FilCod not in (61,90)
				except
				select distinct t1.CodigoFilial, t1.CodigoProduto from IntegraTICravil.Bi.HistoricoCMV as t1 with(nolock)
				where t1.DataEmissao = @execucao

			) as x cross apply YOUR_DATABASE.dbo.GetCustoMercadoria(x.FilCod, x.ProCod, @execucao) as t2
			--
			 inner join YOUR_DATABASE.dbo.PRODUTOS as t3 with(nolock)
			 on t3.ProCod = x.ProCod
			 inner join YOUR_DATABASE.dbo.FAMILIAS as t4 with(nolock)
			 on t4.FamCod = t3.ProFamCod
			 inner join YOUR_DATABASE.dbo.GRUPOS as t5 with(nolock)
			 on t5.GrpCod = t3.ProGrpCod
			 and t5.FamCod = t3.ProFamCod
			 inner join YOUR_DATABASE.dbo.SUBGRUPOS as t6 with(nolock)
			 on t6.FamCod = t3.ProFamCod
			 and t6.GrpCod = t3.ProGrpCod
			 and t6.SubCod = t3.ProSubCod
			 inner join YOUR_DATABASE.dbo.FILIAIS as t7 with(nolock)
			 on t7.FilCod = x.FilCod

		-- decremento
		set @execucao = dateadd(day, -1, @execucao)
	end
	
	SET TRANSACTION ISOLATION LEVEL READ COMMITTED
	SET NOCOUNT OFF
end

----------------------------------------------------------------------------------------------------------------------------------------------------------
-- an�lise dos dados
----------------------------------------------------------------------------------------------------------------------------------------------------------
use IntegraTICravil
go

select x.Data, COUNT(*) as DadosTotais
from
(
select cast(t1.DataEmissao as date) as [Data]
from bi.HistoricoPosicaoEstoque as t1
WHERE t1.DataEmissao >= '20180101' AND t1.DataEmissao < '20180701'
) as x
group by x.Data
order by x.Data DESC










