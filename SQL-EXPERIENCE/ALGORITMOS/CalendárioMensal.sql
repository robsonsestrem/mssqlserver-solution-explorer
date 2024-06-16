---------------------------------------------------------------------------------------------------------------
-- criando calendário mensal de dados
---------------------------------------------------------------------------------------------------------------


Set Nocount On
Set DateFirst 7
Set DateFormat DMY
 
Declare @Calendario Table
 (Semana Int Identity(1,1) ,
  Segunda SmallInt Default null,
  Terca SmallInt Default null, 
  Quarta SmallInt Default null,
  Quinta SmallInt Default null,
   Sexta SmallInt Default null,
   Sabado SmallInt Default Null,
   Domingo SmallInt Default Null)
 
Declare @DataInicial Date
Declare @DataFinal  Date
Declare @Semana  Int
 
Select @DataInicial = '01/04/2016' , @DataFinal = '30/04/2016', @Semana = 1
 
While @DataInicial <= @DataFinal
Begin
  Insert into @Calendario Default Values
 
  While 1=1
     Begin 
       Update @Calendario
        Set Segunda = Case When DatePart(WeekDay,@DataInicial) = 2 Then DatePart(Day,@DataInicial) Else Segunda End,
              Terca = Case When DatePart(WeekDay,@DataInicial) = 3 Then DatePart(Day,@DataInicial) Else Terca End,
              Quarta = Case When DatePart(WeekDay,@DataInicial) = 4 Then DatePart(Day,@DataInicial) Else Quarta End,
              Quinta = Case When DatePart(WeekDay,@DataInicial) = 5 Then DatePart(Day,@DataInicial) Else Quinta End,
              Sexta = Case When DatePart(WeekDay,@DataInicial) = 6 Then DatePart(Day,@DataInicial) Else Sexta End,
              Sabado = Case When DatePart(WeekDay,@DataInicial) = 7 Then DatePart(Day,@DataInicial) Else Sabado End,
              Domingo = Case When DatePart(WeekDay,@DataInicial) = 1 Then DatePart(Day,@DataInicial) Else Domingo End    
       Where Semana = @Semana
       And DatePart(Month,@DataInicial) =  DatePart(Month,@DataFinal)
      If DatePart(WeekDay,@DataInicial) = 1
       Break
         Select @DataInicial = Dateadd(Day,1,@DataInicial)
      End
     Select @DataInicial = Dateadd(Day,1,@DataInicial)
     Set @Semana = @Semana + 1
End
 
Select * From @Calendario


--O segredo deste código encontra-se na execução do Comando Update 
--em conjunto com o Comando Case, ambos, destacados a seguir:


Update @Calendario
        Set Segunda = Case When DatePart(WeekDay,@DataInicial) = 2 Then DatePart(Day,@DataInicial) Else Segunda End,
              Terca = Case When DatePart(WeekDay,@DataInicial) = 3 Then DatePart(Day,@DataInicial) Else Terca End,
              Quarta = Case When DatePart(WeekDay,@DataInicial) = 4 Then DatePart(Day,@DataInicial) Else Quarta End,
              Quinta = Case When DatePart(WeekDay,@DataInicial) = 5 Then DatePart(Day,@DataInicial) Else Quinta End,
              Sexta = Case When DatePart(WeekDay,@DataInicial) = 6 Then DatePart(Day,@DataInicial) Else Sexta End,
              Sabado = Case When DatePart(WeekDay,@DataInicial) = 7 Then DatePart(Day,@DataInicial) Else Sabado End,
              Domingo = Case When DatePart(WeekDay,@DataInicial) = 1 Then DatePart(Day,@DataInicial) Else Domingo End    
       Where Semana = @Semana
       And DatePart(Month,@DataInicial) =  DatePart(Month,@DataFinal)

--Neste bloco de código, estamos realizando a atualização de cada Registro inserido na 
--variável table @Calendario, fazendo a análise para identificar em qual dia da semana 
--e também em qual semana do mês os valores estão sendo acumulados. 
--Para também esta sendo utilizado a Função DatePart em conjunto com as opções Day, WeekDay e Month.


-- Gerando um calendário mensal em tempo de execução, com base, no mês atual [outra maneira]

Select dateadd(month,datediff(month,0,getdate()),0) + number

from master..spt_values n with (nolock)

where number between 0 and day(dateadd(month,datediff(month,-1,getdate()),0) - 1) -1 and type = 'p'

Go