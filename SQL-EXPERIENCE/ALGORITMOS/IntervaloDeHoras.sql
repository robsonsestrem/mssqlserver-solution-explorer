Pesquisando por datas
É comum termos que fazer pesquisas em colunas do tipo date/time buscando por uma determinada data independente da hora. Com isto, se a data na coluna estiver sendo usada consistentemente com a parte hora sendo 0, não haverá problemas. Mas como exemplo, considere uma tabela com os dados abaixo:
ID Data
-- -----------------------
1 2001-02-28 10:00:00.000
2 2002-02-28 13:58:32.823
3 2002-02-29 00:00:00.000
4 2002-02-28 00:00:00.000
Como podemos ver, a coluna Data é usada de forma inconsistente, ou seja, as vezes a parte hora é informada e as vezes não (sendo definida para 00:00:00:000). Os dois últimos registros indicam que a coluna pode ter sido criada para armazenar somente datas, mas os primeiros dois registros indicam que isto não foi forçado pela aplicação.
Como consequência, se você disparar uma consulta querendo saber os registros com a data de 28 fevereiro 2002, o resultado obtido não será o esperado.
SELECT * FROM TableData WHERE Data = 2002-02-28
O resultado apresentará somente a linha 4 ao invés das linhas 2 e 4. Isto acontece porque como a parte hora não foi informada, o SQL Server pesquisará pela data onde o parte hora seja 0. Uma vez que a hora para a linha 2 não é 0, a mesma não é retornada.
Sendo assim, como podemos fazer para contornar este problema ? Se este tipo de consulta for muito utilizada por sua aplicação, uma sugestão é que você utilize range de valores. Exemplo:
SELECT * FROM TableData
WHERE Data BETWEEN 2002-02-28 AND 2002-02-28 23:59:59.997
Lembre-se que a cláusula BETWEEN obtém valores que estão entre o primeiro e o segundo valor informado (também conhecidos como limites inferior e superior). Sendo assim, você não pode definir o limite superior como 2002-02-29 pois se você fizer isto, incorretamente obterá a linha 3. Um outro caminho para obter o resutado esperado é usando operadores de comparação.
SELECT * FROM TableData
WHERE Data >= 2002-02-28 AND Data < 2002-02-29
Caso sua consulta seja utilizada com pouca frequência, você também pode utilizar algumas funções na cláusula WHERE de forma a separar a parte data da parte hora. Por exemplo:
SELECT * FROM TableData
WHERE CAST(FLOOR(CAST(Data AS float)) AS datetime) = 2002-02-28
Isto retornará as linhas 2 e 4. Seguindo o mesmo caminho, se você deseja obter apenas os registros de 28 de fevereiro, independente do ano, você pode utilizar as funções MONTH e DAY conforme abaixo:
SELECT * FROM TableData
WHERE MONTH(Data) = 2 AND DAY(Data) = 28
Isto retornará as linhas 1, 2, e 4.


Read more: http://www.linhadecodigo.com.br/artigo/946/trabalhando-com-valores-date_time-no-sql-server-2000.aspx#ixzz4J6FiJyMK




Pesquisando por hora
Realizar uma consulta que busque por uma hora específica é semelhante a realizar uma consulta que busque apenas por uma data (sem a hora). Se a coluna armazena consistentemente somente a parte referente a hora, a busca pela hora será simples.
Entretanto, diferente de valores data, o valor referente a hora é representado por um valor numérico aproximado.
Para ilustrar a pesquisa apenas pela hora, considere uma tabela com os dados abaixo:
ID Hora
-- -----------------------
1 2002-02-28 10:00:00.000
2 1900-01-01 13:58:32.823
3 1900-01-01 09:59:59.997
4 1900-01-01 10:00:00.000
Aqui a coluna Hora é utilizada de forma insconsistente, ou seja, algumas vezes armazenando somente a hora (a parte data é definida como 1 Janeiro 1900), outras vezes armazenando a data e a hora.
Sendo assim, se você utilizar a consulta abaixo para obter apenas os registros com hora igual a 10:00AM, você terá como resultado apenas a linha 4.
SELECT * FROM TableTime WHERE Hora = ‘10:00:00'
A linha 1 não é retornada porque quando se pesquisa apenas pela hora o SQL Server entende que a parte referente ao dia deve ser 0, o que equivale a 1 Janeiro 1900. Em adição, a linha 3 não é obtida porque embora o valor esteja bastante próximo, o mesmo não é 10:00AM.
Para ignorar a parte data de uma coluna date/time, você pode utilizar expressões que separe o valor date/time de seu componente inteiro (a data).
SELECT * FROM TableTime
WHERE Hora - CAST(FLOOR(CAST(Hora AS float)) AS datetime) = 10:00
Isto retornará as linhas 1 e 4. Infelizmente não existe uma maneira de obter este resultado sem usar uma ou mais funções. Novamente por razões de performance, evite a utilização de funções em campos utilizados em busca. Se você necessitar realizar este tipo de consulta de forma frequente, procure revisar a estrutura de sua tabela e procure criar campos diferentes para o armazenamento da data e da hora.
Se a parte hora for armazenada de forma consistente, ou seja, sem parte referente a data. Você também poderá utilizar queries como as descritas abaixo:
SELECT * FROM TableTime
WHERE Hora BETWEEN 09:59 AND 10:01
OU
SELECT * FROM TableTime
WHERE Hora > 09:59 AND Hora < 10:01
Ambas as consultas retornam as linhas 3 e 4.
Se a parte hora for armazenada de forma inconsistente, então você terá que considerar as partes data e um range de valores hora.
SELECT * FROM TableTime
WHERE Hora - CAST(FLOOR(CAST(Hora AS float)) AS datetime) > 09:59
AND Hora - CAST(FLOOR(CAST(Hora AS float)) AS datetime) < 10:01
Isto retornará as linhas 1, 3, e 4.
Um outro caminho para trabalhar mais facilmente com valores hora é usar o data type smalldatetime no lugar do datetime. Uma vez que o smalldatetime sempre arredonda a parte hora para o minuto mais próximo (acima ou abaixo), as horas que estiverem entre 09:59:29.999 e 10:00:29.998 são armazenadas como 10:00. Se este tipo de arredondamente for suficiente para sua aplicação, então o uso do smalldatetime evitará a necessidade de buscas por range de valores hora.


Read more: http://www.linhadecodigo.com.br/artigo/946/trabalhando-com-valores-date_time-no-sql-server-2000.aspx#ixzz4J6GrGsvo