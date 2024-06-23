DECLARE   @diasRetroagir INT = -15	-- Informar dias retroativos para ver diferença de fragmentação
	    , @dataFiltro DATETIME
SET @dataFiltro = (DATEADD(DAY, @diasRetroagir, (select max(cast(floor(cast(DateReference as float))as datetime)) 
												 from Maintenance.Management.HistoryIndexFragmentation)))
;WITH details
AS (
	select 
	  cast(floor(cast(i.DateReference as float))as datetime)			AS DateReference
	, (select max(cast(floor(cast(DateReference as float))as datetime)) 
	   from Maintenance.Management.HistoryIndexFragmentation)		AS Lastdate
	, i.DatabaseName, i.SchemaName, i.TableName, i.IndexName
	, i.IndexLevel, i.IndexDepth, i.AllocUnitTypeDesc
	, i.AvgFragmentationInPercent	
	from Maintenance.Management.HistoryIndexFragmentation as i
	where i.IndexLevel = 0
	and i.AllocUnitTypeDesc = 'IN_ROW_DATA'
	and i.DatabaseName = 'gescooper90'
	and i.AvgFragmentationInPercent > 10
	and i.[PageCount] > 1000
	and i.DateReference >= @dataFiltro		
   )
, calculate
AS (
	 select 
	 d.DateReference, d.LastDate, d.DatabaseName, d.SchemaName, d.TableName, d.IndexName
	 , d.IndexLevel, d.IndexDepth, d.AllocUnitTypeDesc, d.AvgFragmentationInPercent
	 , ROW_NUMBER() OVER (PARTITION BY d.IndexName ORDER BY d.DateReference)		AS rn
	 , (ROW_NUMBER() OVER (PARTITION BY d.IndexName ORDER BY d.DateReference)) / 2	AS rnDiv2
	 , (ROW_NUMBER() OVER (PARTITION BY d.IndexName ORDER BY d.DateReference)+1) /2 AS rnMaisUmDiv2
	 from details as d
    )

	select --c.rn, c.rnDiv2, c.rnMaisUmDiv2
	c.DatabaseName, c.SchemaName, c.TableName, c.IndexName
	, c.IndexLevel, c.IndexDepth, c.AllocUnitTypeDesc
	, c.AvgFragmentationInPercent																					AS Fragmentation
	, CONVERT(VARCHAR(30), c.DateReference, 105)																	AS DateReference
	--
	, isnull(CASE WHEN c.rn % 2 = 1
		THEN MAX(CASE WHEN rn%2=0 THEN c.AvgFragmentationInPercent END) OVER (PARTITION BY c.IndexName, c.rnDiv2) 
		ELSE MAX(CASE WHEN rn%2=1 THEN c.AvgFragmentationInPercent END) OVER (PARTITION BY c.IndexName, c.rnMaisUmDiv2)
	  END, 0)																										AS LAG
	--
	, isnull(CASE WHEN c.rn % 2 = 1 
				THEN MAX(CASE WHEN rn%2=0 THEN c.AvgFragmentationInPercent END) OVER (PARTITION BY c.IndexName, c.rnMaisUmDiv2) 
				ELSE MAX(CASE WHEN rn%2=1 THEN c.AvgFragmentationInPercent END) OVER (PARTITION BY c.IndexName, c.rnDiv2)
			 END, 0)																								AS LEAD
	--
	, (select cal.AvgFragmentationInPercent from calculate as cal 
	   where cal.DateReference = DATEADD(DAY, @diasRetroagir, c.LastDate) 
	   and cal.IndexName = c.IndexName and cal.TableName = c.TableName 
	   and cal.SchemaName = c.SchemaName and cal.DatabaseName = c.DatabaseName
	   and cal.IndexLevel = c.IndexLevel
	   and cal.IndexDepth = c.IndexDepth
	   and cal.AllocUnitTypeDesc = c.AllocUnitTypeDesc	) 															AS FragXDay
	--
	, CONVERT(VARCHAR(30),DATEADD(DAY, @diasRetroagir, c.LastDate),105)												AS DateFragXDay
	--
	, c.AvgFragmentationInPercent - (select cal.AvgFragmentationInPercent from calculate as cal 
									   where cal.DateReference = DATEADD(DAY, @diasRetroagir, c.LastDate) 
									   and cal.IndexName = c.IndexName and cal.TableName = c.TableName 
									   and cal.SchemaName = c.SchemaName and cal.DatabaseName = c.DatabaseName
									   and cal.IndexLevel = c.IndexLevel
									   and cal.IndexDepth = c.IndexDepth
									   and cal.AllocUnitTypeDesc = c.AllocUnitTypeDesc	)							AS DiffFragLastDayForXDay
	--
	, CONVERT(VARCHAR(30),c.LastDate, 105)																			AS LastDate 
	from calculate as c
	where c.DateReference >= @dataFiltro
	order by 1, 2, 3, 4, 9	-- assim vai juntar melhor os índices conforme fragmentação por data



