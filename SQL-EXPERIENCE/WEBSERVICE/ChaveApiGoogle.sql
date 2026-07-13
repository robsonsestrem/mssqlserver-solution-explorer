/*
	OBJETIVO:
			  (sp_OACreate), enviando um CEP ou endereço e recebendo a resposta em XML.
	PROJETO: mssqlserver-solution-explorer

	REFERÊNCIAS DE URL:
	-- Busca por endereço/CEP:
	--   https://maps.googleapis.com/maps/api/geocode/json?address=1600+Amphitheatre+Parkway,+Mountain+View,+CA&key=YOUR_API_KEY
	--   https://maps.googleapis.com/maps/api/geocode/xml?components=postal_code:89170-000|country:BR&key=YOUR_API_KEY
	-- Busca por latitude/longitude:
	--   https://maps.googleapis.com/maps/api/geocode/json?latlng=40.714224,-73.961452&location_type=ROOFTOP&result_type=street_address&key=YOUR_API_KEY
	-- Referência DevMedia:
	--   http://maps.googleapis.com/maps/api/geocode/json?address=+ endereco + &sensor=false
	-- Como ativar as APIs na biblioteca Google Cloud:
	--   https://pt.stackoverflow.com/questions/232885/problema-com-key-do-google-maps

	CHAVES DE API:
	-- CHAVE CravilSystem  (Maps JavaScript API) -> YOUR_API_KEY
	-- CHAVE ProdutoresMAP (Geocoding API)        -> YOUR_API_KEY
*/


-- Declaração das variáveis de controle da requisição HTTP e da resposta XML
DECLARE
	 @obj            INT
	,@Url            VARCHAR(8000)
	,@resposta       VARCHAR(8000)
	,@xml            XML
	,@endereco_busca VARCHAR(4000) = '89163-020'; --'components=postal_code:89170-000|country:BR'

-- Monta a URL da requisição com o endereço/CEP e a chave de API
SET @Url =
	'https://maps.googleapis.com/maps/api/geocode/xml?address='
	+ @endereco_busca
	+ ' &key=YOUR_API_KEY';

-- Cria o objeto COM e abre a conexão HTTP GET
EXEC sys.sp_OACreate
	@progid      = 'MSXML2.ServerXMLHTTP',
	@objecttoken = @obj OUT,
	@context     = 1;

EXEC sys.sp_OAMethod @obj, 'open', NULL, 'GET', @Url, false;

-- Envia a requisição à API
EXEC sys.sp_OAMethod @obj, 'send';

-- Captura o corpo da resposta HTTP como texto
EXEC sys.sp_OAGetProperty @obj, 'responseText', @resposta OUT;

-- Libera o objeto COM da memória
EXEC sys.sp_OADestroy @obj;

-- Converte a resposta texto para XML aplicando collation para caracteres especiais
SET @xml = @resposta COLLATE SQL_Latin1_General_CP1251_CS_AS;

-- Exibe o XML retornado pela API do Google Geocoding
SELECT @xml;


/*
	CONSULTAS AUXILIARES (referência de validação local de CEP):
	--SELECT l.descricao, * FROM YOUR_DATABASE.System.Logradouro l
	--WHERE l.CEP = '89163020'
	--https://maps.googleapis.com/maps/api/geocode/xml?components=postal_code:89170-000|country:BR&key=YOUR_API_KEY
*/