USE [GesCooper90]
GO

-- =============================================
-- Author:		<Joabel>
-- Create date: <06-08-2014>
-- Description:	<>
-- =============================================
ALTER FUNCTION [dbo].[GetMovimentoFinanceiro] 
(	
	@DataInicial datetime, 
	@DataFinal datetime
)
RETURNS @Financeiro TABLE (
FilialCodigo smallint,
FilialNome varchar(80),
SetorCodigo integer,
SetorNome varchar(80),
SecaoCodigo integer,
SecaoNome varchar(80),
CentroCustoCodigo integer,
CentroCustoNome varchar(80),
NumeroControle integer,
NumeroDocumento integer,
Operacao smallint,
Emissao datetime,
Item int,			-- 28-09-2017
SequenciaItem int,
VendedorCodigo integer,
VendedorNome varchar(80),
ClienteCodigo integer,
ClienteNome varchar(80),
Cidade varchar(80),
CodigoPag smallint,      --adicional
TipoPagamento varchar(30),
Vencimento DateTime,
Valor money
)
AS 
BEGIN
	Declare @Movimentacao Cursor;
	--
	Declare @_FilialCodigo smallint;
	Declare @_FilialNome varchar(80);
	Declare @_SetorCodigo integer;
	Declare @_SetorNome varchar(80);
	Declare @_SecaoCodigo integer;
	Declare @_SecaoNome varchar(80);
	Declare @_CentroCustoCodigo integer;
	Declare @_CentroCustoNome varchar(80);
	Declare @_NumeroControle integer;
	Declare @_NumeroDocumento integer;
	Declare @_Operacao smallint;
	Declare @_Emissao datetime;
	Declare @_Item int;			-- 28-09-2017
	Declare @_SequenciaItem int;
	Declare @_VendedorCodigo integer;
	Declare @_VendedorNome varchar(80);
	Declare @_ClienteCodigo integer
	Declare @_ClienteNome varchar(80);
	Declare @_Cidade varchar(80);
	Declare @_CodigoPag smallint;
	Declare @_TipoPagamento varchar(30);
	Declare @_Vencimento DateTime;
	Declare @_ValorTotalAux money;
	--
	Declare @FilialCodigo smallint;
	Declare @FilialNome varchar(80);
	Declare @SetorCodigo integer;
	Declare @SetorNome varchar(80);
	Declare @SecaoCodigo integer;
	Declare @SecaoNome varchar(80);
	Declare @CentroCustoCodigo integer;
	Declare @CentroCustoNome varchar(80);
	Declare @NumeroControle integer;
	Declare @NumeroDocumento integer;
	Declare @Operacao smallint;
	Declare @Emissao datetime;
	Declare @Item int;			-- 28-09-2017
	Declare @SequenciaItem int;
	Declare @VendedorCodigo integer;
	Declare @VendedorNome varchar(80);
	Declare @ClienteCodigo integer
	Declare @ClienteNome varchar(80);
	Declare @Cidade varchar(80);
	Declare @CodigoPag smallint;      -- adicional
	Declare @TipoPagamento varchar(30);
	Declare @Vencimento DateTime;
	Declare @Valor money;
	Declare @ValorTotal money;

	--Cursor
    Set @Movimentacao = CURSOR FAST_FORWARD

    For select
		 m.Filial as Filial
		,f.FilNomReduzido as Nome Filial
		,m.Setor as Setor
		,setor.SetNom as Nome Setor
		,m.Secao as Seção
		,sec.SecNom as Nome Seção
		,m.CentroCusto as Centro/Custo
		,ce.CenNom as Nome Centro
		,m.NumControle as NumControle
		,m.NF as NF
		,m.Op as Op
		,m.Emissao as Emissão
		,m.Item as Item					-- 28-09-2017
		,m.SequenciaItem as SequenciaItem
		,m.VendRepre as Vend/Repre
		,isnull(repre.TraNom,'') as Nome Repre
		,m.ClienteFornecedor as Cliente/Fornecedor
		,t.TraNom as Nome cliente
		,city.MunNom as Cidade
		,Coalesce( mum2.parCodConta,1) as CodigoPag  -- adicional
		,Case 
			when mum2.parCodConta = 1 then 'À Vista'
			when mum2.parCodConta = 2 then 'Fornecedor'
			when mum2.parCodConta = 3 then 'Adiantamento/Fornecedor'
			when mum2.parCodConta = 4 then 'Dev./Fornecedor'
			when mum2.parCodConta = 5 then 'Transf.Centro Custo'
			when mum2.parCodConta = 6 then 'Bonificação'
			when mum2.parCodConta = 7 then 'Ord/Cred'
			when mum2.parCodConta = 8 then 'Clientes/Crediário'
			when mum2.parCodConta = 9 then 'Depósito/Bancário'
			when mum2.parCodConta = 10 then 'Cheque'
			when mum2.parCodConta = 11 then 'Boleto/Bancario'
			when mum2.parCodConta = 12 then 'Vendedor/Crediário'
			when mum2.parCodConta = 13 then 'Cartão/Débito'
			when mum2.parCodConta = 14 then 'Cartão/Crédito'
			else 'À Vista'
		end as  Tipo/Pag
		,ISNULL(mum2.ParDatVenc, m.Emissao) as Vencimento 
		,mum2.ParVlr
		,SUM(m.ValorBruto) as ValorTotal
	from  vw_MovimentacaoReceita as m with (nolock) 
	inner join TRANSACIONADORES as t with(nolock) on (m.ClienteFornecedor = t.tracod)
	inner join FILIAIS as f with(nolock) on m.Filial = f.FilCod
	--
	left  join movestoquelevel2 mum2 with(nolock) on mum2.NfFilCod = m.Filial and mum2.NfDatEmis = m.Emissao and mum2.nfnumero = m.NumControle
	--
	left join MUNICIPIOS as city with(nolock) on city.MunCod = t.TraMunCod and city.EstCod = t.TraEstCod and city.PaiCod = t.TraPaiCod
	left  join TRANSACIONADORES as repre with (nolock) on repre.TraCod = m.VendRepre
	--
	left join CENTROCUSTO as ce with (nolock) on m.CentroCusto = ce.CenCod
	left join SECAO as setor with(nolock) on m.Setor = setor.SetCod
	left join SECAOLEVEL1 as sec with (nolock) on m.Secao = sec.SecCod and m.Setor = sec.SetCod
	--
	where m.Situacao not in (1,4)
	and m.Op in (18, 44, 48, 54, 60, 77, 80, 81, 85, 138, 151, 172, 202, 204)
	and m.Emissao  between @DataInicial and @DataFinal
	group by m.Filial, f.FilNomReduzido, m.Setor, setor.SetNom, m.Secao, sec.SecNom, m.CentroCusto, ce.CenNom, m.NumControle
	, m.NF, m.Op, m.Emissao, m.Item, m.SequenciaItem, m.VendRepre, repre.TraNom, m.ClienteFornecedor, t.TraNom, city.MunNom, mum2.parCodConta
	, mum2.ParDatVenc, mum2.ParVlr 
	--
	Order by m.Filial, m.Emissao, m.NumControle;    

    --le o cursor
    Open @Movimentacao;
    Fetch Next From @Movimentacao INTO  
		@FilialCodigo,@FilialNome,@SetorCodigo,@SetorNome,@SecaoCodigo,@SecaoNome,@CentroCustoCodigo
		,@CentroCustoNome,@NumeroControle,@NumeroDocumento,@Operacao,@Emissao, @Item, @SequenciaItem	-- 28-09-2017
		,@VendedorCodigo,@VendedorNome,@ClienteCodigo,@ClienteNome,@Cidade,@CodigoPag    -- adicional
		,@TipoPagamento,@Vencimento,@Valor,@ValorTotal;
       
	set @_FilialCodigo = null;
	Set @_ValorTotalAux = @ValorTotal            

    While @@FETCH_STATUS = 0 -- Fetch_Status e se leu algum registro no cursor
    Begin
		--
		Insert Into @Financeiro (FilialCodigo,FilialNome,SetorCodigo,SetorNome,SecaoCodigo,SecaoNome,CentroCustoCodigo,CentroCustoNome,NumeroControle,NumeroDocumento,Operacao,Emissao,Item, SequenciaItem, VendedorCodigo,VendedorNome,ClienteCodigo,ClienteNome,Cidade,CodigoPag,TipoPagamento,Vencimento,Valor) 
			             values (@FilialCodigo,@FilialNome,@SetorCodigo,@SetorNome,@SecaoCodigo,@SecaoNome,@CentroCustoCodigo,@CentroCustoNome,@NumeroControle,@NumeroDocumento,@Operacao,@Emissao,@Item, @SequenciaItem, @VendedorCodigo,@VendedorNome,@ClienteCodigo,@ClienteNome,@Cidade,@CodigoPag,@TipoPagamento,@Vencimento,coalesce(@Valor,@ValorTotal))

		--guarda ultimo registro
		Set @_FilialCodigo = @FilialCodigo;
		Set @_FilialNome = @FilialNome;
		Set @_SetorCodigo = @SetorCodigo;
		Set @_SetorNome = @SetorNome;
		Set @_SecaoCodigo = @SecaoCodigo;
		Set @_SecaoNome = @SecaoNome;
		Set @_CentroCustoCodigo = @CentroCustoCodigo;
		Set @_CentroCustoNome = @CentroCustoNome;
		Set @_NumeroControle = @NumeroControle;
		Set @_NumeroDocumento = @NumeroDocumento;
		Set @_Operacao = @Operacao;
		Set @_Emissao = @Emissao;
		Set @_Item = @Item						-- 28-09-2017
		Set @_SequenciaItem = @SequenciaItem
		Set @_VendedorCodigo = @VendedorCodigo;
		Set @_VendedorNome = @VendedorNome;
		Set @_ClienteCodigo = @ClienteCodigo;
		Set @_ClienteNome = @ClienteNome;
		Set @_Cidade = @Cidade;
		Set @_CodigoPag = @CodigoPag;	-- adicional
		Set @_TipoPagamento = @TipoPagamento;
		Set @_Vencimento = @Vencimento;
		--calcula o valor de saldo para a vista
		if (@Valor is not null)
			Set @_ValorTotalAux = @_ValorTotalAux - @Valor
		Else
			Set @_ValorTotalAux = @_ValorTotalAux - @ValorTotal
			
		--le proximo registro
		Fetch Next From @Movimentacao INTO  
			@FilialCodigo,@FilialNome,@SetorCodigo,@SetorNome,@SecaoCodigo,@SecaoNome,@CentroCustoCodigo
			,@CentroCustoNome,@NumeroControle,@NumeroDocumento,@Operacao,@Emissao,@Item, @SequenciaItem	-- 28-09-2017
			,@VendedorCodigo,@VendedorNome,@ClienteCodigo,@ClienteNome ,@Cidade
			,@CodigoPag,@TipoPagamento,@Vencimento,@Valor,@ValorTotal

		if (@_FilialCodigo <> @FilialCodigo or  @_Emissao <> @Emissao or @_NumeroControle <> @NumeroControle) 
		begin
			if (@_ValorTotalAux > 0)
				Insert Into @Financeiro (FilialCodigo,FilialNome,SetorCodigo,SetorNome,SecaoCodigo,SecaoNome,CentroCustoCodigo,CentroCustoNome,NumeroControle,NumeroDocumento,Operacao,Emissao, Item, SequenciaItem,VendedorCodigo,VendedorNome,ClienteCodigo,ClienteNome,Cidade,CodigoPag,TipoPagamento,Vencimento,Valor) 
								 values (@_FilialCodigo,@_FilialNome,@_SetorCodigo,@_SetorNome,@_SecaoCodigo,@_SecaoNome,@_CentroCustoCodigo,@_CentroCustoNome,@_NumeroControle,@_NumeroDocumento,@_Operacao,@_Emissao,@_Item, @_SequenciaItem, @_VendedorCodigo,@_VendedorNome,@_ClienteCodigo,@_ClienteNome,@_Cidade,1,'À Vista',@_Emissao,@_ValorTotalAux)
				
			--novo total
			Set @_ValorTotalAux = @ValorTotal
		end

	End; 
    
    Close @Movimentacao;
    DEALLOCATE @Movimentacao;
    
	RETURN;
END;
GO


