--USE GesCooper90
--GO

--select f.FilCod,f.FilNom,f.FilNomReduzido,f.FilNfeCCerti, f.FilNfeSenCer 
--from FILIAIS AS f WITH(NOLOCK)
--where FilFlag2 = 0

--select f.FilCod,f.FilNom,f.FilNomReduzido,f.FilNfeCCerti,f.FilNfeSenCer  
--from FILIAIS AS f WITH(NOLOCK)
--where f.FilCod = 82

--DIRETÓRIO COM ARQUIVO ANTIGO
--L:\GerenciadorNFe\Certificados\CRAVIL 07.06.15-07.06.16.pfx
--------------------------------------------------------------
--DIRETÓRIO COM ARQUIVO NOVO
--L:\GerenciadorNFe\Certificados\CRAVIL 01.06.16-01.06.17.pfx
   
             
USE gescooper90 

BEGIN TRAN 

	BEGIN try 
		UPDATE FILIAIS 
		SET    FilNfeCCerti ='L:\GerenciadorNFe\Certificados\CRAVIL 21.05.18-21.05.19.pfx',
			   FilNfeSenCer ='cravil01'
		where FilFlag2 = 0			--condição para todas filiais ativas é -> where FilFlag2 = 0

		PRINT 'DEU BOA' 

		COMMIT 
	END try 

		BEGIN catch 
			PRINT 'DEU MERDA' 

			SELECT Error_number()  AS Número de erro, 
				   Error_message() AS Mensagem 

			ROLLBACK 
		END catch 


