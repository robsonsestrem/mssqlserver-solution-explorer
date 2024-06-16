use GesCooper90
go

set dateformat dmy

declare @ano smallint = 2014
declare @mes smallint = 01

declare @datainicial datetime = convert(date,'01/'+
case when @mes < 10 then '0' else '' end + convert(varchar,@mes)+'/'+convert(varchar,@ano))
declare @datafinal datetime = dateadd(day,-1,dateadd(month,1,@datainicial))

Select  I.ItemProCod, P.ProNom,P.ProNbmCod, m.NfNumDoc, m.nfechnfe, convert(varchar,m.NfDatEmis,103) nfdatemis, 
 case when coalesce(M.NfModDocCod,'') = '' then ModDocCod else NfModDocCod end NfModDocCod,  I.ItemPisCofinsCST, 
I.ItemPerPis, I.ItemPerCofins ,I.ItemTotInf
from MOVESTOQUELEVEL1 as I with (nolock)
inner join movestoque as m with (nolock) 
on (M.NfFilCod =  I.NfFilCod and M.NfDatEmis = I.NfDatEmis and M.NfNumero = I.NfNumero)
inner join (select filcod from FIliais as f with (nolock) where FilCod <> 99) f ON (m.nffilcod = f.filcod)
inner join 
	(select 
		opeestcod,  
		ModDocCod
	from 
		OPERACAO as O with (nolock) 
	where  
		O.OpeEstMovCod in(8,5)
		and O.OpeEst107Flag = 1 ) o on (O.OpeEstCod = M.NfOpeEstCod)
inner join PRODUTOS As P With (nolock) on (P.ProCod  = I.ItemProCod)
Where 
I.NfDatEmis between @datainicial and @datafinal
and M.NfSituacao in(2,3,5) 
and I.ItemPisCofinsCST in('01','04','05','06','08','09','49') and I.ItemProCod > 0
