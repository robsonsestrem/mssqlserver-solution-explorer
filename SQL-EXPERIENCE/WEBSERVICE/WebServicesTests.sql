/*
	OBJETIVO: Scripts de teste para consumo de Web Services externos via OLE Automation
			  (sp_OACreate): Google Geocoding API (XML), API Bemean CEP (JSON)
			  e ViaCEP (XML).
	PROJETO: mssqlserver-solution-explorer
*/
-- ============================================================
-- TESTE 1 — Google Geocoding API
-- Resposta XML, busca por CEP/endereço
-- ============================================================

-- Declara variáveis de controle HTTP e resposta XML para o Google Geocoding
DECLARE
	 @obj            INT
	,@Url            VARCHAR(8000)
	,@resposta       VARCHAR(8000)
	,@xml            XML
	--,@json          VARCHAR(4000)
	,@endereco_busca VARCHAR(4000) = '88300000'; --'components=postal_code:89170-000|country:BR'

-- Monta a URL com o endereço CEP e a chave de API do Google
SET @Url =
	'https://maps.googleapis.com/maps/api/geocode/xml?address='
	+ @endereco_busca
	+ ' &key=YOUR_API_KEY';

-- Cria o objeto COM, abre a conexão GET e envia a requisição
EXEC sys.sp_OACreate
	@progid      = 'MSXML2.ServerXMLHTTP',
	@objecttoken = @obj OUT,
	@context     = 1;

EXEC sys.sp_OAMethod @obj, 'open', NULL, 'GET', @Url, false;
EXEC sys.sp_OAMethod @obj, 'send';

-- Captura o corpo da resposta e libera o objeto COM
EXEC sys.sp_OAGetProperty @obj, 'responseText', @resposta OUT;
EXEC sys.sp_OADestroy @obj;

-- Converte a resposta para XML com collation adequado para caracteres especiais
SET @xml = @resposta COLLATE SQL_Latin1_General_CP1251_CS_AS;
--SET @json = @resposta

-- Exibe o XML retornado pela API
SELECT @xml;
--SELECT JSON_QUERY(@resposta)


-- ============================================================
-- TESTE 2 — API Bemean CEP (resposta JSON)
-- ============================================================

-- Declara variáveis de controle HTTP para a API Bemean (retorno JSON)
DECLARE
	 @obj      INT
	,@Url      VARCHAR(255)
	,@resposta VARCHAR(8000)
	,@Nr_CEP   VARCHAR(20) = '89163020';

-- Monta a URL com o CEP informado
SET @Url = 'https://cep-bemean.herokuapp.com/api/br/' + @Nr_CEP;

-- Cria o objeto COM, abre a conexão GET e envia a requisição
EXEC sys.sp_OACreate 'MSXML2.ServerXMLHTTP', @obj OUT;
EXEC sys.sp_OAMethod @obj, 'open', NULL, 'GET', @Url, FALSE;
EXEC sys.sp_OAMethod @obj, 'send';

-- Captura o corpo da resposta e libera o objeto COM
EXEC sys.sp_OAGetProperty @obj, 'responseText', @resposta OUT;
EXEC sys.sp_OADestroy @obj;

-- Exibe o JSON retornado pela API Bemean
SELECT @resposta;


-- ============================================================
-- TESTE 3 — ViaCEP API (resposta XML)
-- ============================================================

-- Declara variáveis de controle HTTP e resposta XML para o ViaCEP
DECLARE
	 @obj      INT
	,@Url      VARCHAR(255)
	,@resposta VARCHAR(8000)
	,@xml      XML
	,@Nr_CEP   VARCHAR(20) = '89163020';

-- Monta a URL com o CEP e o formato de resposta XML
SET @Url = 'http://viacep.com.br/ws/' + @Nr_CEP + '/xml';

-- Cria o objeto COM, abre a conexão GET e envia a requisição
EXEC sys.sp_OACreate 'MSXML2.ServerXMLHTTP', @obj OUT;
EXEC sys.sp_OAMethod @obj, 'open', NULL, 'GET', @Url, FALSE;
EXEC sys.sp_OAMethod @obj, 'send';

-- Captura o corpo da resposta e libera o objeto COM
EXEC sys.sp_OAGetProperty @obj, 'responseText', @resposta OUT;
EXEC sys.sp_OADestroy @obj;

-- Converte a resposta para XML com collation adequado para caracteres especiais
SET @xml = @resposta COLLATE SQL_Latin1_General_CP1251_CS_AS;

-- Exibe o XML retornado pelo ViaCEP
SELECT @xml;
