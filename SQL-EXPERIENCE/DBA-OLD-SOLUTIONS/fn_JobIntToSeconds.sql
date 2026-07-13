----------------------------------------------------------------------------------------------------------------------------------------
-- Ajusta/converte o time de campos de views de sistema de jobs - TESTADA NO BASELINE DI�RIO
----------------------------------------------------------------------------------------------------------------------------------------
http://www.sqlservercentral.com/blogs/briankmcdonald/2010/10/29/sqlbigeek_1920_s-function-friday-_1320_-convert-job-duration-to-seconds/print/
https://glutenfreesql.wordpress.com/2012/08/03/view-summary-of-sql-server-agent-jobs/

USE YOUR_DATABASE
GO

/****** Object:  UserDefinedFunction [dbo].[ufn_JobIntToSeconds]    Script Date: 19/04/2017 11:14:09 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION Management.[fn_JobIntToSeconds]
(
      @run_duration INT
/*=========================================================================
Created By: Brian K. McDonald, MCDBA, MCSD (www.SQLBIGeek.com)
Email:      bmcdonald@SQLBIGeek.com
Twitter:    @briankmcdonald
Date:       10/29/2010
Purpose:    Convert the duration of a job to seconds
            A value of 13210 would be 1 hour, 32 minutes and 10 seconds,
            but I want to return this value in seconds. Which is 5530!
            Then I can sum all of the values and to find total duration.
 
Usage:      SELECT dbo.fn_JobIntToSeconds (13210)
----------------------------------------------------------------------------
Modification History
----------------------------------------------------------------------------
 
==========================================================================*/
)
RETURNS INT
WITH ENCRYPTION
AS
BEGIN
 
RETURN
	  CASE
            --hours, minutes and seconds
            WHEN LEN(@run_duration) > 4 THEN CONVERT(VARCHAR(4),LEFT(@run_duration,LEN(@run_duration)-4)) * 3600
             + LEFT(RIGHT(@run_duration,4),2) * 60 + RIGHT(@run_duration,2)
            --minutes and seconds
            WHEN LEN(@run_duration) = 4 THEN LEFT(@run_duration,2) * 60 + RIGHT(@run_duration,2)
            WHEN LEN(@run_duration) = 3 THEN LEFT(@run_duration,1) * 60 + RIGHT(@run_duration,2)
      ELSE --only seconds    
            RIGHT(@run_duration,2) 
      END
END

GO


