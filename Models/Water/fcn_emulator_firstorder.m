function [sbsn_em_output, sbsn_em_data] = fcn_emulator_firstorder(SWATemdata, landuse, sbsn_order_idx, decade_str, cnutrient_adjustment_table)

    sbsn_em_fromland = fcn_emulator_fromland(SWATemdata,landuse,sbsn_order_idx);
    
    sbsn_em_in = sbsn_em_fromland;
    
    sbsn_em_data = fcn_emulator_instream(SWATemdata,sbsn_em_in,sbsn_order_idx);
    
    sbsn_em_output = fcn_sbsn_summary_calc(SWATemdata, sbsn_em_data, decade_str, sbsn_order_idx, cnutrient_adjustment_table);
       
end