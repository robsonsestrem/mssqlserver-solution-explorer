--use GesCooper90
--go
--select filcod, FilNfeDatHorManDes from FILIAIS
--where FilCod = 1 
--filflag2 = 0
--and FilCod <> 90

-- ciclo de teste
-- @sexta02 para @quinta02
-- @sexta02 para @quarta
-- @sexta02 para @segunda

-- @segunda para @sexta01
-- @segunda para @quinta01
-- @segunda para @quarta01
--select DATEPART(WEEKDAY,GETDATE()), DATEPART(WEEKDAY,DATEADD(DAY,-1,GETDATE()))

-- CRITÉRIO DA DIFERENÇA DE 1 DIA SOMENTE DE SEGUNDA À SEXTA
declare 
		@quarta01 datetime = '20170607'
	   ,@quinta01 datetime = '20170608'
	   ,@sexta01 datetime = '20170609'
		   ,@sabado datetime = '20170610'
		   ,@domingo datetime = '20170611'
	   ,@segunda datetime = '20170612'
	   ,@terca datetime = '20170613'
	   ,@quarta datetime = '20170614'
	   ,@quinta02 datetime = '20170615'
	   ,@sexta02 datetime = '20170616'	 
	     	   

	  -- if(DATEDIFF(DAY,@quinta01, @sexta02) <= 3 and datepart(WEEKDAY,@quinta01) = 6)
		 --  begin
			--print 'funcionando'
		 --  end
	   
	  -- if(DATEDIFF(DAY,@quinta01, @sexta02) < 2 and datepart(WEEKDAY,@quinta01) <> 6)
		 --  begin
			--print 'funcionando'
		 --  end

	  -- if(DATEDIFF(DAY,@quinta01, @sexta02) >= 2 and datepart(WEEKDAY,@quinta01) <> 6)
		 --  begin
			--print 'falha'
		 --  end
	  
	  -- if(DATEDIFF(DAY,@quinta01, @sexta02) > 3 and datepart(WEEKDAY,@quinta01) = 6)
		 -- begin
			--print 'falha'
		 -- end

/*
SIMPLIFICANDO UM POUCO - SE FALHOU NUM DIA, NO OUTRO DIA VAI SER ALERTADO
*/

 if(	(DATEDIFF(DAY,@quinta02, @sexta02) <= 3 and datepart(WEEKDAY,@quinta02) = 6) OR (DATEDIFF(DAY,@quinta02, @sexta02) < 2 and datepart(WEEKDAY,@quinta02) <> 6)	)
		   begin
			print 'funcionando'
		   end
	   	 
 if(	(DATEDIFF(DAY,@quinta02, @sexta02) >= 2 and datepart(WEEKDAY,@quinta02) <> 6) OR (DATEDIFF(DAY,@quinta02, @sexta02) > 3 and datepart(WEEKDAY,@quinta02) = 6)	)
		   begin
			print 'falha'
		   end
	  
	   


		






