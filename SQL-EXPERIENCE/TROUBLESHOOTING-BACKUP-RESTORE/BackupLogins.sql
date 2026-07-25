/*
    OBJETIVO: Gerar scripts para recriação de logins do SQL Server,
              incluindo senhas com hash, SIDs e configurações de política,
              permitindo transferência de logins entre instâncias.
    PROJETO: mssqlserver-solution-explorer

    REFERÊNCIAS:
    https://support.microsoft.com/en-us/help/918992/how-to-transfer-logins-and-passwords-between-instances-of-sql-server
*/

USE master;
GO

-- ============================================================
-- Procedure para converter varbinary em hexadecimal
-- ============================================================
IF OBJECT_ID ('sp_hexadecimal') IS NOT NULL
    DROP PROCEDURE sp_hexadecimal;
GO

CREATE PROCEDURE sp_hexadecimal
    @binvalue VARBINARY(256),
    @hexvalue VARCHAR(514) OUTPUT
AS
BEGIN
    DECLARE @charvalue VARCHAR(514);
    DECLARE @i INT;
    DECLARE @length INT;
    DECLARE @hexstring CHAR(16);

    SELECT @charvalue = '0x';
    SELECT @i = 1;
    SELECT @length = DATALENGTH(@binvalue);
    SELECT @hexstring = '0123456789ABCDEF';

    WHILE (@i <= @length)
    BEGIN
        DECLARE @tempint INT;
        DECLARE @firstint INT;
        DECLARE @secondint INT;

        SELECT @tempint = CONVERT(INT, SUBSTRING(@binvalue, @i, 1));
        SELECT @firstint = FLOOR(@tempint / 16);
        SELECT @secondint = @tempint - (@firstint * 16);
        SELECT @charvalue = @charvalue
            + SUBSTRING(@hexstring, @firstint + 1, 1)
            + SUBSTRING(@hexstring, @secondint + 1, 1);

        SELECT @i = @i + 1;
    END;

    SELECT @hexvalue = @charvalue;
END;
GO


-- ============================================================
-- Procedure para gerar scripts de criação de logins
-- ============================================================
IF OBJECT_ID ('sp_help_revlogin') IS NOT NULL
    DROP PROCEDURE sp_help_revlogin;
GO

CREATE PROCEDURE sp_help_revlogin
    @login_name SYSNAME = NULL
AS
BEGIN
    DECLARE @name SYSNAME;
    DECLARE @type VARCHAR(1);
    DECLARE @hasaccess INT;
    DECLARE @denylogin INT;
    DECLARE @is_disabled INT;
    DECLARE @PWD_varbinary VARBINARY(256);
    DECLARE @PWD_string VARCHAR(514);
    DECLARE @SID_varbinary VARBINARY(85);
    DECLARE @SID_string VARCHAR(514);
    DECLARE @tmpstr VARCHAR(1024);
    DECLARE @is_policy_checked VARCHAR(3);
    DECLARE @is_expiration_checked VARCHAR(3);
    DECLARE @defaultdb SYSNAME;

    IF (@login_name IS NULL)
        DECLARE login_curs CURSOR FOR
        SELECT
            p.sid
          , p.name
          , p.type
          , p.is_disabled
          , p.default_database_name
          , l.hasaccess
          , l.denylogin
        FROM
            sys.server_principals AS p
            LEFT JOIN sys.syslogins AS l
                ON l.name = p.name
        WHERE
            p.type IN ('S', 'G', 'U')
            AND p.name <> 'sa';
    ELSE
        DECLARE login_curs CURSOR FOR
        SELECT
            p.sid
          , p.name
          , p.type
          , p.is_disabled
          , p.default_database_name
          , l.hasaccess
          , l.denylogin
        FROM
            sys.server_principals AS p
            LEFT JOIN sys.syslogins AS l
                ON l.name = p.name
        WHERE
            p.type IN ('S', 'G', 'U')
            AND p.name = @login_name;

    OPEN login_curs;

    FETCH NEXT FROM login_curs
    INTO @SID_varbinary, @name, @type, @is_disabled, @defaultdb, @hasaccess, @denylogin;

    IF (@@FETCH_STATUS = -1)
    BEGIN
        PRINT 'No login(s) found.';
        CLOSE login_curs;
        DEALLOCATE login_curs;
        RETURN -1;
    END;

    SET @tmpstr = '/* sp_help_revlogin script ';
    PRINT @tmpstr;
    SET @tmpstr = '** Generated ' + CONVERT(VARCHAR, GETDATE()) + ' on ' + @@SERVERNAME + ' */';
    PRINT @tmpstr;
    PRINT '';

    WHILE (@@FETCH_STATUS <> -1)
    BEGIN
        IF (@@FETCH_STATUS <> -2)
        BEGIN
            PRINT '';
            SET @tmpstr = '-- Login: ' + @name;
            PRINT @tmpstr;

            IF (@type IN ('G', 'U'))
            BEGIN
                -- NT authenticated account/group
                SET @tmpstr = 'CREATE LOGIN ' + QUOTENAME(@name)
                    + ' FROM WINDOWS WITH DEFAULT_DATABASE = [' + @defaultdb + ']';
            END
            ELSE
            BEGIN
                -- SQL Server authentication
                -- obtain password and sid
                SET @PWD_varbinary = CAST(LOGINPROPERTY(@name, 'PasswordHash') AS VARBINARY(256));
                EXEC sp_hexadecimal @PWD_varbinary, @PWD_string OUTPUT;
                EXEC sp_hexadecimal @SID_varbinary, @SID_string OUTPUT;

                -- obtain password policy state
                SELECT @is_policy_checked =
                    CASE is_policy_checked
                        WHEN 1 THEN 'ON'
                        WHEN 0 THEN 'OFF'
                        ELSE NULL
                    END
                FROM
                    sys.sql_logins
                WHERE
                    name = @name;

                SELECT @is_expiration_checked =
                    CASE is_expiration_checked
                        WHEN 1 THEN 'ON'
                        WHEN 0 THEN 'OFF'
                        ELSE NULL
                    END
                FROM
                    sys.sql_logins
                WHERE
                    name = @name;

                SET @tmpstr = 'CREATE LOGIN ' + QUOTENAME(@name)
                    + ' WITH PASSWORD = ' + @PWD_string + ' HASHED'
                    + ', SID = ' + @SID_string
                    + ', DEFAULT_DATABASE = [' + @defaultdb + ']';

                IF (@is_policy_checked IS NOT NULL)
                BEGIN
                    SET @tmpstr = @tmpstr + ', CHECK_POLICY = ' + @is_policy_checked;
                END;

                IF (@is_expiration_checked IS NOT NULL)
                BEGIN
                    SET @tmpstr = @tmpstr + ', CHECK_EXPIRATION = ' + @is_expiration_checked;
                END;
            END;

            IF (@denylogin = 1)
            BEGIN
                -- login is denied access
                SET @tmpstr = @tmpstr + '; DENY CONNECT SQL TO ' + QUOTENAME(@name);
            END
            ELSE IF (@hasaccess = 0)
            BEGIN
                -- login exists but does not have access
                SET @tmpstr = @tmpstr + '; REVOKE CONNECT SQL TO ' + QUOTENAME(@name);
            END;

            IF (@is_disabled = 1)
            BEGIN
                -- login is disabled
                SET @tmpstr = @tmpstr + '; ALTER LOGIN ' + QUOTENAME(@name) + ' DISABLE';
            END;

            PRINT @tmpstr;
        END;

        FETCH NEXT FROM login_curs
        INTO @SID_varbinary, @name, @type, @is_disabled, @defaultdb, @hasaccess, @denylogin;
    END;

    CLOSE login_curs;
    DEALLOCATE login_curs;
    RETURN 0;
END;
GO

-- ============================================================
-- Exemplo de uso
-- ============================================================

EXEC sp_help_revlogin;
