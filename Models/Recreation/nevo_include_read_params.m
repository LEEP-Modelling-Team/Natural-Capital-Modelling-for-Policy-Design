% Model references and parameters
% -------------------------------
switch model.type
    case 'mnl3'
        model.tbl_v1     = 'v1_mnl3';
        model.tbl_params = 'betas_rec_mnl3';
        model.params     = 'b_mnl3';
    case 'nmnl1'
        model.tbl_v1     = 'v1_nmnl1';
        model.tbl_params = 'parameters_nmnl1';
        model.params     = 'b_nmnl1';    
    case 'nmnl2'
        model.tbl_v1     = 'v1_nmnl2';
        model.tbl_params = 'parameters_nmnl2';
        model.params     = 'b_nmnl2';
    case 'nmnl3'
        model.tbl_v1     = 'v1_nmnl3';
        model.tbl_params = 'parameters_nmnl3';
        model.params     = 'b_nmnl3';
    case 'xmnl1'
        model.tbl_v1     = 'v1_xmnl1';
        model.tbl_params = 'parameters_xmnl1';
        model.params     = 'b_xmnl1';
    case 'xmnl2'
        model.tbl_v1     = 'v1_xmnl2';
        model.tbl_params = 'parameters_xmnl2';
        model.params     = 'b_xmnl2';
    case 'xmnl3'
        model.tbl_v1     = 'v1_xmnl3';
        model.tbl_params = 'parameters_xmnl3';
        model.params     = 'b_xmnl3';
end

sqlquery = strcat('SELECT * FROM nevo.', model.tbl_params);
curs = exec(conn,sqlquery);
setdbprefs('DataReturnFormat','cellarray')
curs = fetch(curs);
params = curs.Data;
close(curs);
