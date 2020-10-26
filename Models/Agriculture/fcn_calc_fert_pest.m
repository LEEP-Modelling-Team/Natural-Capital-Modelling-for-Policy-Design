function fert_pest_info = fcn_calc_fert_pest(PV, out_structure)    
    
    %% fcn_calc_fert_pest
    % Take decadal averages of crop hectares from agricultural model
    % (contained in out structure - defined in fcn_collect_output)
    % Convert to SWAT crops.
    % Multiply by application rates of fertilizers and pesticides.

    %% Convert to SWAT crops
    
    % Wheat is the same
    SWAT.wheat_ha_20 = out_structure.wheat_ha_20;
    SWAT.wheat_ha_30 = out_structure.wheat_ha_30;
    SWAT.wheat_ha_40 = out_structure.wheat_ha_40;
    SWAT.wheat_ha_50 = out_structure.wheat_ha_50;
    
    % Combine winter and spring barley
    SWAT.barley_ha_20 = out_structure.wbar_ha_20 + out_structure.sbar_ha_20;
    SWAT.barley_ha_30 = out_structure.wbar_ha_30 + out_structure.sbar_ha_30;
    SWAT.barley_ha_40 = out_structure.wbar_ha_40 + out_structure.sbar_ha_40;
    SWAT.barley_ha_50 = out_structure.wbar_ha_50 + out_structure.sbar_ha_50;
    
    % Oil seed rape is the same
    SWAT.osr_ha_20 = out_structure.osr_ha_20;
    SWAT.osr_ha_30 = out_structure.osr_ha_30;
    SWAT.osr_ha_40 = out_structure.osr_ha_40;
    SWAT.osr_ha_50 = out_structure.osr_ha_50;
    
    % Potatoes are the same
    SWAT.pot_20 = out_structure.pot_ha_20;
    SWAT.pot_30 = out_structure.pot_ha_30;
    SWAT.pot_40 = out_structure.pot_ha_40;
    SWAT.pot_50 = out_structure.pot_ha_50;
    
    % Sugarbeet is the same
    SWAT.sb_ha_20 = out_structure.sb_ha_20;
    SWAT.sb_ha_30 = out_structure.sb_ha_30;
    SWAT.sb_ha_40 = out_structure.sb_ha_40;
    SWAT.sb_ha_50 = out_structure.sb_ha_50;
    
    % Other crops are split into maize (corn in SWAT) and othcer (oats in SWAT)
    % Use PV.p_maize and PV.p_othcer (precalculated proportions of maize and
    % othcer in other crops) to do this
    SWAT.corn_ha_20 = PV.p_maize .* out_structure.other_ha_20;
    SWAT.corn_ha_30 = PV.p_maize .* out_structure.other_ha_30;
    SWAT.corn_ha_40 = PV.p_maize .* out_structure.other_ha_40;
    SWAT.corn_ha_50 = PV.p_maize .* out_structure.other_ha_50;
    SWAT.oats_ha_20 = PV.p_othcer .* out_structure.other_ha_20;
    SWAT.oats_ha_30 = PV.p_othcer .* out_structure.other_ha_30;
    SWAT.oats_ha_40 = PV.p_othcer .* out_structure.other_ha_40;
    SWAT.oats_ha_50 = PV.p_othcer .* out_structure.other_ha_50;

    %% Calculate kg of fertilizers and pesticides used on agricultural land per year (kg/year)
    % To do this, multiply application rate (supplied by Lorena) by number of
    % hectares for each crop and sum
    % Could multiply values by 10 to get total kgs used in decade (not so useful?)
    % Provide values for fertizilers (nitrogen and phosphorus), pesticides, and
    % total in each of the decades
    fert_pest_info.fert_nitr_20 = 120*SWAT.wheat_ha_20 + 100*SWAT.barley_ha_20 + 120*SWAT.osr_ha_20 + 150*SWAT.pot_20 + 80*SWAT.sb_ha_20 + 50*SWAT.corn_ha_20 + 60*SWAT.oats_ha_20;
    fert_pest_info.fert_nitr_30 = 120*SWAT.wheat_ha_30 + 100*SWAT.barley_ha_30 + 120*SWAT.osr_ha_30 + 150*SWAT.pot_30 + 80*SWAT.sb_ha_30 + 50*SWAT.corn_ha_30 + 60*SWAT.oats_ha_30;
    fert_pest_info.fert_nitr_40 = 120*SWAT.wheat_ha_40 + 100*SWAT.barley_ha_40 + 120*SWAT.osr_ha_40 + 150*SWAT.pot_40 + 80*SWAT.sb_ha_40 + 50*SWAT.corn_ha_40 + 60*SWAT.oats_ha_40;
    fert_pest_info.fert_nitr_50 = 120*SWAT.wheat_ha_50 + 100*SWAT.barley_ha_50 + 120*SWAT.osr_ha_50 + 150*SWAT.pot_50 + 80*SWAT.sb_ha_50 + 50*SWAT.corn_ha_50 + 60*SWAT.oats_ha_50;
    fert_pest_info.fert_phos_20 = 70*SWAT.wheat_ha_20 + 70*SWAT.barley_ha_20 + 35*SWAT.osr_ha_20 + 200*SWAT.pot_20 + 50*SWAT.sb_ha_20 + 55*SWAT.corn_ha_20 + 70*SWAT.oats_ha_20;
    fert_pest_info.fert_phos_30 = 70*SWAT.wheat_ha_30 + 70*SWAT.barley_ha_30 + 35*SWAT.osr_ha_30 + 200*SWAT.pot_30 + 50*SWAT.sb_ha_30 + 55*SWAT.corn_ha_30 + 70*SWAT.oats_ha_30;
    fert_pest_info.fert_phos_40 = 70*SWAT.wheat_ha_40 + 70*SWAT.barley_ha_40 + 35*SWAT.osr_ha_40 + 200*SWAT.pot_40 + 50*SWAT.sb_ha_40 + 55*SWAT.corn_ha_40 + 70*SWAT.oats_ha_40;
    fert_pest_info.fert_phos_50 = 70*SWAT.wheat_ha_50 + 70*SWAT.barley_ha_50 + 35*SWAT.osr_ha_50 + 200*SWAT.pot_50 + 50*SWAT.sb_ha_50 + 55*SWAT.corn_ha_50 + 70*SWAT.oats_ha_50;
    fert_pest_info.pest_20 = 6.8*SWAT.wheat_ha_20 + 5.2*SWAT.barley_ha_20 + 4.8*SWAT.osr_ha_20 + 13.8*SWAT.pot_20 + 2.2*SWAT.sb_ha_20 + 1.1*SWAT.corn_ha_20 + 3*SWAT.oats_ha_20;
    fert_pest_info.pest_30 = 6.8*SWAT.wheat_ha_30 + 5.2*SWAT.barley_ha_30 + 4.8*SWAT.osr_ha_30 + 13.8*SWAT.pot_30 + 2.2*SWAT.sb_ha_30 + 1.1*SWAT.corn_ha_30 + 3*SWAT.oats_ha_30;
    fert_pest_info.pest_40 = 6.8*SWAT.wheat_ha_40 + 5.2*SWAT.barley_ha_40 + 4.8*SWAT.osr_ha_40 + 13.8*SWAT.pot_40 + 2.2*SWAT.sb_ha_40 + 1.1*SWAT.corn_ha_40 + 3*SWAT.oats_ha_40;
    fert_pest_info.pest_50 = 6.8*SWAT.wheat_ha_50 + 5.2*SWAT.barley_ha_50 + 4.8*SWAT.osr_ha_50 + 13.8*SWAT.pot_50 + 2.2*SWAT.sb_ha_50 + 1.1*SWAT.corn_ha_50 + 3*SWAT.oats_ha_50;
    fert_pest_info.tot_fert_pest_20 = fert_pest_info.fert_nitr_20 + fert_pest_info.fert_phos_20 + fert_pest_info.pest_20;
    fert_pest_info.tot_fert_pest_30 = fert_pest_info.fert_nitr_30 + fert_pest_info.fert_phos_30 + fert_pest_info.pest_30;
    fert_pest_info.tot_fert_pest_40 = fert_pest_info.fert_nitr_40 + fert_pest_info.fert_phos_40 + fert_pest_info.pest_40;
    fert_pest_info.tot_fert_pest_50 = fert_pest_info.fert_nitr_50 + fert_pest_info.fert_phos_50 + fert_pest_info.pest_50;
    
    %% Convert structure to table before returning
    % Need new2kid variable for joining onto main out structure later
    fert_pest_info = struct2table(fert_pest_info);
    fert_pest_info.new2kid = out_structure.new2kid;
    
end
