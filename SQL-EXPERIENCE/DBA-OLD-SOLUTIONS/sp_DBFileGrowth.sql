use YOUR_DATABASE
go
ALTER PROCEDURE Management.[sp_DBFileGrowth]
WITH EXECUTE AS OWNER, ENCRYPTION
AS
 BEGIN
     SET NOCOUNT ON;

     DECLARE @message_body XML;

     WHILE(1 = 1)
         BEGIN
             WAITFOR(
             RECEIVE TOP (1) @message_body = CAST([message_body] AS XML) FROM [dbo].[Audit_DBFileGrowth_Queue]), TIMEOUT 1000;

             IF(@@RowCount = 1)
                 BEGIN				 
                     INSERT INTO Management.HistoryDBFileGrowth
                     (DateInsert,
                      [EventType],
                      [PostTime],
                      [SPID],
                      [DatabaseID],
                      [NTDomainName],
                      [HostName],
                      [ClientProcessID],
                      [ApplicationName],
                      [LoginName],
                      [Duration],
                      [StartTime],
                      [EndTime],
                      [IntegerData],
                      [ServerName],
                      [DatabaseName],
                      [FileName],
                      [LoginSid],
                      [EventSequence],
                      [IsSystem],
                      [SessionLoginName]
                     )
                     SELECT GETDATE(),
                            @message_body.value('(/EVENT_INSTANCE/EventType)[1]', 'nvarchar(max)') AS [EventType],
                            @message_body.value('(/EVENT_INSTANCE/PostTime)[1]', 'nvarchar(max)') AS [PostTime],
                            @message_body.value('(/EVENT_INSTANCE/SPID)[1]', 'nvarchar(max)') AS [SPID],
                            DB_NAME(@message_body.value('(/EVENT_INSTANCE/DatabaseID)[1]', 'nvarchar(max)')) AS [DatabaseID],
                            @message_body.value('(/EVENT_INSTANCE/NTDomainName)[1]', 'nvarchar(max)') AS [NTDomainName],
                            @message_body.value('(/EVENT_INSTANCE/HostName)[1]', 'nvarchar(max)') AS [HostName],
                            @message_body.value('(/EVENT_INSTANCE/ClientProcessID)[1]', 'nvarchar(max)') AS [ClientProcessID],
                            @message_body.value('(/EVENT_INSTANCE/ApplicationName)[1]', 'nvarchar(max)') AS [ApplicationName],
                            @message_body.value('(/EVENT_INSTANCE/LoginName)[1]', 'nvarchar(max)') AS [LoginName],
                            @message_body.value('(/EVENT_INSTANCE/Duration)[1]', 'nvarchar(max)') AS [Duration],
                            @message_body.value('(/EVENT_INSTANCE/StartTime)[1]', 'nvarchar(max)') AS [StartTime],
                            @message_body.value('(/EVENT_INSTANCE/EndTime)[1]', 'nvarchar(max)') AS [EndTime],
                            @message_body.value('(/EVENT_INSTANCE/IntegerData)[1]', 'nvarchar(max)') AS [IntegerData],
                            @message_body.value('(/EVENT_INSTANCE/ServerName)[1]', 'nvarchar(max)') AS [ServerName],
                            @message_body.value('(/EVENT_INSTANCE/DatabaseName)[1]', 'nvarchar(max)') AS [DatabaseName],
                            @message_body.value('(/EVENT_INSTANCE/FileName)[1]', 'nvarchar(max)') AS [FileName],
                            @message_body.value('(/EVENT_INSTANCE/LoginSid)[1]', 'nvarchar(max)') AS [LoginSid],
                            @message_body.value('(/EVENT_INSTANCE/EventSequence)[1]', 'nvarchar(max)') AS [EventSequence],
                            @message_body.value('(/EVENT_INSTANCE/IsSystem)[1]', 'nvarchar(max)') AS [IsSystem],
                            @message_body.value('(/EVENT_INSTANCE/SessionLoginName)[1]', ' [nvarchar](max)') AS [SessionLoginName];

				 	-- enviar e-mail
				    DECLARE 				
					@Assunto VARCHAR(200) = @@SERVERNAME + ' - Aten��o Foi Acionado Autogrowth em Datafile(s)',
					@Destinatario VARCHAR(50) = 'suporte@cravil.com.br',
					@Mensagem VARCHAR(MAX)
            		      
					SET @Mensagem = '
					Prezado DBA,<br>
					Verifique os logs, ocorreu autocrescimento em algun(s) datafiles, detalhes abaixo:
					<br>Inst�ncia: ' + @@SERVICENAME + ' 
					<br>Servidor: ' + @@SERVERNAME + '
					<br><br> 
					<TABLE border=1 cellpadding=2 cellspacing=0 font-family:Arial;font-size:14px>															
										<tr align = left>
											<td bgcolor=#0B0B61 width=200> <font color=white>EventType			</td>
											<td bgcolor=#0B0B61 width=200> <font color=white>PostTime				</td>											
											<td bgcolor=#0B0B61 width=200> <font color=white>HostName				</td>
											<td bgcolor=#0B0B61 width=200> <font color=white>ApplicationName		</td>
											<td bgcolor=#0B0B61 width=200> <font color=white>LoginName			</td>
											<td bgcolor=#0B0B61 width=200> <font color=white>Duration				</td>										
											<td bgcolor=#0B0B61 width=200> <font color=white>StartTime			</td>
											<td bgcolor=#0B0B61 width=200> <font color=white>EndTime				</td>
											<td bgcolor=#0B0B61 width=200> <font color=white>Database			</td>
											<td bgcolor=#0B0B61 width=200> <font color=white>FileName				</td>
											<td bgcolor=#0B0B61 width=200> <font color=white>SessionLogin		</td>
										</tr>
									  '	
					SELECT  @Mensagem = @Mensagem + 
				'<tr align = left>'+
				'<td>' +  lower(@message_body.value('(/EVENT_INSTANCE/EventType)[1]', 'nvarchar(max)'))		+ '</td>' +
				'<td>' +  replace(replace(@message_body.value('(/EVENT_INSTANCE/PostTime)[1]', 'nvarchar(max)'),'T',' '),'-','/')			+ '</td>' +								 						
				'<td>' +  @message_body.value('(/EVENT_INSTANCE/HostName)[1]', 'nvarchar(max)') 			+ '</td>' +							
				'<td>' +  @message_body.value('(/EVENT_INSTANCE/ApplicationName)[1]', 'nvarchar(max)')		+ '</td>' +				   	   
				'<td>' +  @message_body.value('(/EVENT_INSTANCE/LoginName)[1]', 'nvarchar(max)')			+ '</td>' +		
				'<td>' +  @message_body.value('(/EVENT_INSTANCE/Duration)[1]', 'nvarchar(max)')				+ '</td>' +		
				'<td>' +  replace(replace(@message_body.value('(/EVENT_INSTANCE/StartTime)[1]', 'nvarchar(max)'),'T',' '),'-','/')			+ '</td>' +		
				'<td>' +  replace(replace(@message_body.value('(/EVENT_INSTANCE/EndTime)[1]', 'nvarchar(max)'),'T',' '),'-','/')			+ '</td>' +						 	
				'<td>' +  @message_body.value('(/EVENT_INSTANCE/DatabaseName)[1]', 'nvarchar(max)')			+ '</td>' +	
				'<td>' +  @message_body.value('(/EVENT_INSTANCE/FileName)[1]', 'nvarchar(max)')				+ '</td>' +	
				'<td>' +  @message_body.value('(/EVENT_INSTANCE/SessionLoginName)[1]', ' [nvarchar](max)')	+ '</td>' +	
				
				'</tr> </table><br>'

					EXEC msdb.dbo.sp_send_dbmail
					@profile_name = 'CRAVIL' ,	
					@recipients = @Destinatario ,	
					@subject = @Assunto,			
					@body = @Mensagem,				
					@body_format = 'HTML'
                 end			

         END; --fim while
	SET NOCOUNT OFF;
 END;
GO