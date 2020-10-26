function conn = fcn_connect_database(server_flag)

    if server_flag
        
        % Add class path (if not in the class path)  
        DB.p = '/opt/routing/nevo/postgresql-42.1.4.jar';  
        if ~ismember(DB.p,javaclasspath)
            javaaddpath(DB.p);
        end
        
        % Database connection
        DB.datasource  = 'nevo';
        DB.username    = 'postgres';
        DB.password    = 'Defra01$';
        DB.driver      = 'org.postgresql.Driver';
        DB.url         = 'jdbc:postgresql://localhost:5432/nevo';
        conn           = database(DB.datasource,DB.username,DB.password,DB.driver,DB.url);
        % clear DB;
        
    else
        
        % Add class path (if not in the class path)
        DB.p = './postgresql-42.0.0.jre7.jar'; 
        if ~ismember(DB.p,javaclasspath)  
           javaaddpath(DB.p)  
        end
        
        % Database connection
        DB.datasource  = 'nathan';
        DB.username    = 'postgres';
        DB.password    = '1234';
        DB.driver      = 'org.postgresql.Driver';
        DB.url         = 'jdbc:postgresql://localhost:5432/nathan';
        conn           = database(DB.datasource,DB.username,DB.password,DB.driver,DB.url);
        
    end
