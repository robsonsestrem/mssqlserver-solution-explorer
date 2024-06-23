use Maintenance
go

CREATE FUNCTION Management.fn_ValidEmail(@Ds_Email varchar(max))
RETURNS BIT
AS BEGIN

    DECLARE @Retorno BIT = 0

    SELECT @Retorno = 1
    WHERE @Ds_Email NOT LIKE '%[^a-z,0-9,@,.,_,-]%'
    AND @Ds_Email LIKE '%_@_%_.__%'
    AND @Ds_Email NOT LIKE '%_@@_%_.__%'

    RETURN @Retorno

END

-- select Management.fn_ValidEmail('robson@cravil.com.br')