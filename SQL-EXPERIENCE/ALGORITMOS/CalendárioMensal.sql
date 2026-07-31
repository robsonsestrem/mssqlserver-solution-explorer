/*
 *
	OBJETIVO: Geração de calendário mensal em tempo de execução, populando uma
			  table variable com dias da semana distribuídos em colunas, utilizando
			  loops WHILE com UPDATE condicional via CASE e DatePart.
	PROJETO: mssqlserver-solution-explorer
 *
 */
-- ============================================================
-- Calendário Mensal via Table Variable e Loop WHILE
-- ============================================================

SET NOCOUNT ON
SET DATEFIRST 7
SET DATEFORMAT DMY

-- Declaração da table variable para armazenar o calendário mensal
DECLARE @Calendario TABLE
(
    Semana INT IDENTITY(1,1)
    ,Segunda SMALLINT DEFAULT NULL
    ,Terca SMALLINT DEFAULT NULL
    ,Quarta SMALLINT DEFAULT NULL
    ,Quinta SMALLINT DEFAULT NULL
    ,Sexta SMALLINT DEFAULT NULL
    ,Sabado SMALLINT DEFAULT NULL
    ,Domingo SMALLINT DEFAULT NULL
)

-- Declaração de variáveis de controle do loop
DECLARE @DataInicial DATE
DECLARE @DataFinal DATE
DECLARE @Semana INT

-- Inicialização das datas do mês de referência
SELECT 
    @DataInicial = '01/04/2016'
    ,@DataFinal = '30/04/2016'
    ,@Semana = 1

-- Loop externo: itera até a data final do mês
WHILE @DataInicial <= @DataFinal
BEGIN
    -- Insere uma nova linha para a semana atual
    INSERT INTO @Calendario DEFAULT VALUES

    -- Loop interno: popula os dias da semana até encontrar domingo
    WHILE 1 = 1
    BEGIN
        -- Atualização condicional da linha atual com base no dia da semana
        UPDATE @Calendario
        SET Segunda = CASE WHEN DATEPART(WEEKDAY, @DataInicial) = 2 THEN DATEPART(DAY, @DataInicial) ELSE Segunda END
            ,Terca = CASE WHEN DATEPART(WEEKDAY, @DataInicial) = 3 THEN DATEPART(DAY, @DataInicial) ELSE Terca END
            ,Quarta = CASE WHEN DATEPART(WEEKDAY, @DataInicial) = 4 THEN DATEPART(DAY, @DataInicial) ELSE Quarta END
            ,Quinta = CASE WHEN DATEPART(WEEKDAY, @DataInicial) = 5 THEN DATEPART(DAY, @DataInicial) ELSE Quinta END
            ,Sexta = CASE WHEN DATEPART(WEEKDAY, @DataInicial) = 6 THEN DATEPART(DAY, @DataInicial) ELSE Sexta END
            ,Sabado = CASE WHEN DATEPART(WEEKDAY, @DataInicial) = 7 THEN DATEPART(DAY, @DataInicial) ELSE Sabado END
            ,Domingo = CASE WHEN DATEPART(WEEKDAY, @DataInicial) = 1 THEN DATEPART(DAY, @DataInicial) ELSE Domingo END
        WHERE Semana = @Semana
            AND DATEPART(MONTH, @DataInicial) = DATEPART(MONTH, @DataFinal)

        -- Se encontrou domingo, encerra o loop interno
        IF DATEPART(WEEKDAY, @DataInicial) = 1
            BREAK

        -- Avança para o próximo dia
        SELECT @DataInicial = DATEADD(DAY, 1, @DataInicial)
    END

    -- Avança para o próximo dia e incrementa o contador de semana
    SELECT @DataInicial = DATEADD(DAY, 1, @DataInicial)
    SET @Semana = @Semana + 1
END

-- Exibição do calendário gerado
SELECT * FROM @Calendario

-- ============================================================
-- Análise Técnica: UPDATE com CASE
-- ============================================================

/*
O segredo deste código encontra-se na execução do comando UPDATE
em conjunto com o comando CASE, ambos destacados a seguir:

UPDATE @Calendario
SET Segunda = CASE WHEN DATEPART(WEEKDAY, @DataInicial) = 2 THEN DATEPART(DAY, @DataInicial) ELSE Segunda END
    ,Terca = CASE WHEN DATEPART(WEEKDAY, @DataInicial) = 3 THEN DATEPART(DAY, @DataInicial) ELSE Terca END
    ,Quarta = CASE WHEN DATEPART(WEEKDAY, @DataInicial) = 4 THEN DATEPART(DAY, @DataInicial) ELSE Quarta END
    ,Quinta = CASE WHEN DATEPART(WEEKDAY, @DataInicial) = 5 THEN DATEPART(DAY, @DataInicial) ELSE Quinta END
    ,Sexta = CASE WHEN DATEPART(WEEKDAY, @DataInicial) = 6 THEN DATEPART(DAY, @DataInicial) ELSE Sexta END
    ,Sabado = CASE WHEN DATEPART(WEEKDAY, @DataInicial) = 7 THEN DATEPART(DAY, @DataInicial) ELSE Sabado END
    ,Domingo = CASE WHEN DATEPART(WEEKDAY, @DataInicial) = 1 THEN DATEPART(DAY, @DataInicial) ELSE Domingo END
WHERE Semana = @Semana
    AND DATEPART(MONTH, @DataInicial) = DATEPART(MONTH, @DataFinal)

Neste bloco de código, estamos realizando a atualização de cada registro inserido na
table variable @Calendario, fazendo a análise para identificar em qual dia da semana
e também em qual semana do mês os valores estão sendo acumulados.

Para isso, está sendo utilizada a função DATEPART em conjunto com as opções DAY, WEEKDAY e MONTH.
*/

-- ============================================================
-- Alternativa: Calendário Mensal via spt_values
-- ============================================================

-- Geração de calendário mensal em tempo de execução com base no mês atual
SELECT DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()), 0) + n.number
FROM master..spt_values AS n WITH (NOLOCK)
WHERE n.number BETWEEN 0 AND DAY(DATEADD(MONTH, DATEDIFF(MONTH, -1, GETDATE()), 0) - 1) - 1
    AND n.type = 'P'
GO
