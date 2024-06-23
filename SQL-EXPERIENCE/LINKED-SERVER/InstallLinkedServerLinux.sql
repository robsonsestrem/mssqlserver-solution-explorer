/*
 *
 *
    ###################################################################################################################################################
    ####### PESQUISA -> SQL Server Linked Server ######################################################################################################
    ###################################################################################################################################################
    *** ADD Linked Server - via T-SQL
    https://github.com/MicrosoftDocs/sql-docs/blob/live/docs/relational-databases/system-stored-procedures/sp-addlinkedserver-transact-sql.md
    https://dirceuresende.com/blog/sql-server-como-consultar-informacoes-do-active-directory-ad-utilizando-linked-server-adsi/#Como_criar_o_Linked_Server
    
    
    *** SQLNCLI -> msodbcsql17
    https://medium.com/@jjagadish.in/installing-the-microsoft-odbc-driver-for-sql-server-on-redhat-enterprise-server-6-and-7-c2c08d4ffd37
    
    https://superuser.com/questions/1309124/how-i-can-create-linked-server-on-linux-sqlserver-2017
    
    https://stackoverflow.com/questions/73978438/add-providers-to-linux-sql-server-2019
    
    https://documentacoes.wordpress.com/2018/10/24/connect-to-sql-server-using-microsoft-odbc-driver-in-centos-7/
    
    
    *** msodbcsql18
    https://github.com/MicrosoftDocs/sql-docs/blob/live/docs/connect/odbc/linux-mac/installing-the-microsoft-odbc-driver-for-sql-server.md
    
    
    *** Instalação Default no CentOS com unixODBC (msodbcsql17)
    https://www.sqlshack.com/manage-sql-databases-in-centos-install-sql-server-on-centos/
    
    
    ###################################################################################################################################################
    ##################### INSTALAÇÃO UTILIZADA - msodbcsql18 #####################
    ###################################################################################################################################################
    https://github.com/MicrosoftDocs/sql-docs/blob/live/docs/connect/odbc/linux-mac/installing-the-microsoft-odbc-driver-for-sql-server.md
    > sudo yum update -y
    
    > curl https://packages.microsoft.com/config/rhel/7/prod.repo | sudo tee /etc/yum.repos.d/mssql-release.repo
    
    > sudo yum remove unixODBC-utf16 unixODBC-utf16-devel #to avoid conflicts
    > sudo ACCEPT_EULA=Y yum install -y msodbcsql18
    # optional: for bcp and sqlcmd
    > sudo ACCEPT_EULA=Y yum install -y mssql-tools18
    > echo 'export PATH="$PATH:/opt/mssql-tools18/bin"' >> ~/.bashrc
    > source ~/.bashrc
    # optional: for unixODBC development headers
    > sudo yum install -y unixODBC-devel
    
    
    ###################################################################################################################################################
    ##################### INSTALAÇÃO UTILIZADA - msodbcsql17 #####################
    ###################################################################################################################################################
    https://medium.com/@jjagadish.in/installing-the-microsoft-odbc-driver-for-sql-server-on-redhat-enterprise-server-6-and-7-c2c08d4ffd37
    
    > sudo yum remove unixODBC-utf16 unixODBC-utf16-devel #to avoid conflicts
    > sudo ACCEPT_EULA=Y yum install msodbcsql17
    # optional: for bcp and sqlcmd
    > sudo ACCEPT_EULA=Y yum install mssql-tools
    > echo ‘export PATH=”$PATH:/opt/mssql-tools/bin”’ >> ~/.bash_profile
    > echo ‘export PATH=”$PATH:/opt/mssql-tools/bin”’ >> ~/.bashrc
    > source ~/.bashrc
    # optional: for unixODBC development headers
    > sudo yum install unixODBC-devel
    
    
    ###################################################################################################################################################
    ##################### VERIFICAR INSTALAÇÃO NO LINUX - DESINSTALAÇÃO #####################
    ###################################################################################################################################################
    > odbcinst -j
    
    > cat /etc/odbcinst.ini
    
    > yum list installed | grep msodbcsql
    
    -- Desinstalar - depois é só conferir na lista se ficou 1 só.
    -- Obs.: ele já desinstala as dependências, exemplo mssql-tools.
    > sudo yum remove msodbcsql17
    
    
    ###################################################################################################################################################
    ##################### ERROS #####################
    Enabling 'remote proc trans' is not supported on this instance. (.Net SqlClient Data Provider)
    ------------------------------
    For help, click: https://docs.microsoft.com/sql/relational-databases/errors-events/mssqlserver-7224-database-engine-error
    
    ------------------------------
    Server Name: 119.8.155.38
    Error Number: 7224
    Severity: 16
    State: 1
    Procedure: master.dbo.sp_serveroption
    Line Number: 142
    ------------------------------------------------------------------------------------------------
    Msg 7222, Level 16, State 1, Procedure sys.sp_MSaddserver_internal, Line 60 [Batch Start Line 1]
    Only a SQL Server provider is allowed on this instance.
    
    ------------------------------------------------------------------------------------------------
    Msg 7224, Level 16, State 1, Procedure master.dbo.sp_serveroption, Line 142 [Batch Start Line 44]
    Enabling 'remote proc trans' is not supported on this instance.
      
 *  
 *   
 */

