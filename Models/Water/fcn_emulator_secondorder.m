function [sbsn_em_output, sbsn_em_data] = fcn_emulator_secondorder(SWATemdata, landuse, sbsn_order_idx, decade_str, sbsn_em_fromupstream, cnutrient_adjustment_table)

    sbsn_em_fromland = fcn_emulator_fromland(SWATemdata, landuse, sbsn_order_idx);
    
    sbsn_em_in = cell2struct(cellfun(@(x) x',cellfun(@(x,y) sum(horzcat(x,y),2),cellfun(@(x) x',struct2cell(sbsn_em_fromland),'UniformOutput',false),struct2cell(sbsn_em_fromupstream),'UniformOutput',false),'UniformOutput',false),fieldnames(sbsn_em_fromland));
    
    sbsn_em_data = fcn_emulator_instream(SWATemdata, sbsn_em_in, sbsn_order_idx);
    
    sbsn_em_output = fcn_sbsn_summary_calc(SWATemdata, sbsn_em_data, decade_str, sbsn_order_idx, cnutrient_adjustment_table);

end