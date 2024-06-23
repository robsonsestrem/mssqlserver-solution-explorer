USE CooperSystem
GO

SELECT * FROM CooperSystem.System.Logradouro t1
WHERE t1.CEP = '89086380'

SELECT * FROM CooperSystem.System.Cidade c
WHERE c.Descricao = 'indaial'
AND c.UF = 'SC'

SELECT max(l.id_logradouro) FROM CooperSystem.System.Logradouro l
-- último lançado = 1019499

select * from System.Logradouro as t1
where id_logradouro = 1019500


INSERT INTO CooperSystem.System.Logradouro
(
    CEP,
    id_logradouro,
    tipo,
    descricao,
    id_cidade,
    UF,
    complemento,
    descricao_sem_numero,
    descricao_cidade,
    codigo_cidade_ibge,
    descricao_bairro
)
VALUES
(
    '89086380', -- CEP - varchar
    1019503, -- id_logradouro - int
    'Rua', -- tipo - varchar
    'Rua Johann Schwarz', -- descricao - varchar
    4264, -- id_cidade - int
    'SC', -- UF - varchar
    '', -- complemento - varchar
    'Rua Johann Schwarz', -- descricao_sem_numero - varchar
    'Indaial', -- descricao_cidade - varchar
    4207502, -- codigo_cidade_ibge - int
    'Encano' -- descricao_bairro - varchar
)