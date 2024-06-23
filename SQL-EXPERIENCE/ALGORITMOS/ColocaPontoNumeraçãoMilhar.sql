--------------------------------------------------------------------------------------------------------------------------
-- conversão coloca vírgula/ponto a cada milhar dos números 
--------------------------------------------------------------------------------------------------------------------------

declare @free_space_mb bigint

set @free_space_mb = 187406112745679

select 
REVERSE (SUBSTRING (REVERSE (CONVERT (VARCHAR (30),	CONVERT (MONEY, @free_space_mb), 1)), 4, 15))						as MegabytesVirgula, 
REPLACE( REVERSE (SUBSTRING (REVERSE (CONVERT (VARCHAR (30),	CONVERT (MONEY, @free_space_mb), 1)), 4, 15)),',','.' )	as MegabytesPonto, 
cast(@free_space_mb/1024 as decimal(15,2))																				as Gibabytes 