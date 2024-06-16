-- Exemplo informado o endereço/CEP:
-- https://maps.googleapis.com/maps/api/geocode/json?address=1600+Amphitheatre+Parkway,+Mountain+View,+CA&key=YOUR_API_KEY
-- https://maps.googleapis.com/maps/api/geocode/xml?components=postal_code:89170-000|country:BR&key=AIzaSyDT9zAhec7M3g-t2mxhl2Os5kDgfhsTZwE
-- Exemplo informado latitude longitude
-- https://maps.googleapis.com/maps/api/geocode/json?latlng=40.714224,-73.961452&location_type=ROOFTOP&result_type=street_address&key=YOUR_API_KEY

-- Lembrar de ativar as API's do google maps (geocoding) na biblioteca
-- CHAVE CravilSystem (Maps JavaScript API) -> AIzaSyDT9zAhec7M3g-t2mxhl2Os5kDgfhsTZwE
-- CHAVE ProdutoresMAP (Geocoding API)		-> AIzaSyABpBuBeEzl4nM_PXdj-kn0e22cfxt47TU

--Como ativar API
--https://pt.stackoverflow.com/questions/232885/problema-com-key-do-google-maps

-- devmedia
-- http://maps.googleapis.com/maps/api/geocode/json?address=+ endereco + &sensor=false

  DECLARE 
        @obj INT,
        @Url VARCHAR(8000),
        @resposta VARCHAR(8000),
        @xml XML,
        @endereco_busca VARCHAR(4000) = '89163-020'--'components=postal_code:89170-000|country:BR'
 
    SET @Url = 'https://maps.googleapis.com/maps/api/geocode/xml?address='+ @endereco_busca +' &key=AIzaSyABpBuBeEzl4nM_PXdj-kn0e22cfxt47TU' 
 
    EXEC sys.sp_OACreate @progid = 'MSXML2.ServerXMLHTTP', @objecttoken = @obj OUT, @context = 1
    EXEC sys.sp_OAMethod @obj, 'open', NULL, 'GET', @Url, false
    EXEC sys.sp_OAMethod @obj, 'send'
    EXEC sys.sp_OAGetProperty @obj, 'responseText', @resposta OUT
    EXEC sys.sp_OADestroy @obj
 
 
    SET @xml = @resposta COLLATE SQL_Latin1_General_CP1251_CS_AS

	SELECT @xml



	--SELECT l.descricao, * FROM CooperSystem.System.Logradouro l
	--WHERE l.CEP = '89163020'
	--https://maps.googleapis.com/maps/api/geocode/xml?components=postal_code:89170-000|country:BR&key=AIzaSyDT9zAhec7M3g-t2mxhl2Os5kDgfhsTZwE


	--SELECT l.descricao, * FROM CooperSystem.System.Logradouro l
	--WHERE l.CEP = '89163020'

	