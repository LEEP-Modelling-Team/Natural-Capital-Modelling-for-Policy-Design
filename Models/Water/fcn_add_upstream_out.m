function sb_em_fromupstream = fcn_add_upstream_out(bsn_em_data,secondorder)

    F = fieldnames(bsn_em_data{secondorder(2)});
    F_logic = [true true true true false false true true];
    
    if length(secondorder) == 3
        D2 = struct2cell(bsn_em_data{secondorder(2)});
        D3 = struct2cell(bsn_em_data{secondorder(3)});
        bsn_em_data_temp2 = cell2struct(D2(F_logic),F(F_logic));
        bsn_em_data_temp3 = cell2struct(D3(F_logic),F(F_logic));
        
        sb_em_fromupstream = cell2struct(cellfun(@(x,y) sum(horzcat(x,y),2),struct2cell(bsn_em_data_temp2),struct2cell(bsn_em_data_temp3),'UniformOutput',false),fieldnames(bsn_em_data_temp2));
    elseif length(secondorder) == 4
        D2 = struct2cell(bsn_em_data{secondorder(2)});
        D3 = struct2cell(bsn_em_data{secondorder(3)});
        D4 = struct2cell(bsn_em_data{secondorder(4)});
        bsn_em_data_temp2 = cell2struct(D2(F_logic),F(F_logic));
        bsn_em_data_temp3 = cell2struct(D3(F_logic),F(F_logic));
        bsn_em_data_temp4 = cell2struct(D4(F_logic),F(F_logic));
        sb_em_fromupstream = cell2struct(cellfun(@(x,y,z) sum(horzcat(x,y,z),2),struct2cell(bsn_em_data_temp2),struct2cell(bsn_em_data_temp3),struct2cell(bsn_em_data_temp4),'UniformOutput',false),fieldnames(bsn_em_data_temp2));
    end

end