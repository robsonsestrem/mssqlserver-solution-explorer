--------------------------------------------------------------------------------------------------------------
-- http://www.tek-tips.com/viewthread.cfm?qid=1284504
-- Conversões para trazer dias, horas, minutos, segundos etc...
--------------------------------------------------------------------------------------------------------------
Declare @Temp Table (ArrivalDate DateTime)

Set DateFormat MDY
insert Into @Temp Values('10-01-2006 18:00:00')
insert Into @Temp Values('09-30-2006 11:30:00')
insert Into @Temp Values('09-29-2006 20:00:00')
insert Into @Temp Values('10-02-2006 08:00:00')
insert Into @Temp Values('10-01-2006 15:00:00')
insert Into @Temp Values('09-27-2006 00:09:00')

Select     *,
        DateDiff(Hour, ArrivalDate, GetDate()) / 24 as Days,
        DateDiff(Minute, DateAdd(Day, DateDiff(Hour, ArrivalDate, GetDate()) / 24, ArrivalDate), GetDate()) / 60 As Hours,
        DateDiff(Second, DateAdd(Hour, DateDiff(Minute, DateAdd(Day, DateDiff(Hour, ArrivalDate, GetDate()) / 24, ArrivalDate), GetDate()) / 60, DateAdd(Day, DateDiff(Hour, ArrivalDate, GetDate()) / 24, ArrivalDate)), GetDate())/60 As Seconds
From     @Temp