------------------------------------------------------------------------------------------------------------------------------------------
-- Get sem tratamento
------------------------------------------------------------------------------------------------------------------------------------------
  DECLARE 
        @obj INT,
        @Url VARCHAR(8000),
        @resposta VARCHAR(8000),
        @xml xml,
		--@json varchar(4000),
        @endereco_busca VARCHAR(4000) = '88300000'--'components=postal_code:89170-000|country:BR'
 
    SET @Url = 'https://maps.googleapis.com/maps/api/geocode/xml?address='+ @endereco_busca +' &key=AIzaSyABpBuBeEzl4nM_PXdj-kn0e22cfxt47TU' 
 
    EXEC sys.sp_OACreate @progid = 'MSXML2.ServerXMLHTTP', @objecttoken = @obj OUT, @context = 1
    EXEC sys.sp_OAMethod @obj, 'open', NULL, 'GET', @Url, false
    EXEC sys.sp_OAMethod @obj, 'send'
    EXEC sys.sp_OAGetProperty @obj, 'responseText', @resposta OUT
    EXEC sys.sp_OADestroy @obj
  
    SET @xml = @resposta COLLATE SQL_Latin1_General_CP1251_CS_AS
	--set @json = @resposta

	SELECT @xml
	--select JSON_QUERY(@resposta)
------------------------------------------------------------------------------------------------------------------------------------------
-- Get sem tratamento (JSON)
------------------------------------------------------------------------------------------------------------------------------------------
DECLARE 
        @obj INT,
        @Url VARCHAR(255),
        @resposta VARCHAR(8000),        
		@Nr_CEP varchar(20) = '89163020'
	SET @Url = 'https://cep-bemean.herokuapp.com/api/br/' + @Nr_CEP
 
    EXEC sys.sp_OACreate 'MSXML2.ServerXMLHTTP', @obj OUT
    EXEC sys.sp_OAMethod @obj, 'open', NULL, 'GET', @Url, FALSE
    EXEC sys.sp_OAMethod @obj, 'send'
    EXEC sys.sp_OAGetProperty @obj, 'responseText', @resposta OUT
    EXEC sys.sp_OADestroy @obj
		 
	select @resposta


------------------------------------------------------------------------------------------------------------------------------------------
-- Get sem tratamento
------------------------------------------------------------------------------------------------------------------------------------------
    DECLARE 
        @obj INT,
        @Url VARCHAR(255),
        @resposta VARCHAR(8000),  
		@xml xml,      
		@Nr_CEP varchar(20) = '89163020'

	SET @Url = 'http://viacep.com.br/ws/' + @Nr_CEP + '/xml'
 
    EXEC sys.sp_OACreate 'MSXML2.ServerXMLHTTP', @obj OUT
    EXEC sys.sp_OAMethod @obj, 'open', NULL, 'GET', @Url, FALSE
    EXEC sys.sp_OAMethod @obj, 'send'
    EXEC sys.sp_OAGetProperty @obj, 'responseText', @resposta OUT
    EXEC sys.sp_OADestroy @obj

	SET @xml = @resposta COLLATE SQL_Latin1_General_CP1251_CS_AS
	select @xml