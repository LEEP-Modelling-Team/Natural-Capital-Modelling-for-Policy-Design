function [CFT_Mach_Em] = CalcCFTMachEm(LandOrder)
% Calculates the machinery emissions from farming certain land types
% LandOrders land types into an array congruent with the LandOrdering from the main
% program
%
% Original code from Sylvia Vetter, University of Aberdeen
% Based on the Cool Farm Tool
% 
% NB: Make sure the CFTnames match up to the CFTname types in "LandOrder" variable.
% -- These come from the Ag model; if there are changes there then they
% will need to be made in the code. A more elegant solution would be better
% long term; look into this when a lot more land types are added.

%clear;

%% CFTvales as specified by Cool Farm Tool:
CFTname = cell(1,length(LandOrder));
CFTval  = zeros(1, length(LandOrder));


%CFTname{1} = 's_osrape';
CFTname{1} = 'osrape';
CFTval(1) = 113.2281;

CFTname{2} = 'cer';
CFTval(2) = 152.1364;

CFTname{3} = 'root';
CFTval(3) = 130.3541;

CFTname{4} = 'tgrass';
CFTval(4) = 44.4030;

CFTname{5} = 'pgrass';
CFTval(5) = 44.4030;

CFTname{6} = 'rgraz';
CFTval(6) = 0;


%% Match LandOrdering to main program and return array.
% pre-all CFT_Mach_Em
CFT_Mach_Em = zeros(1, length(LandOrder));
for i = 1:length(LandOrder)
    CFT_Mach_Em(i)=CFTval(strmatch(LandOrder(i),CFTname,'exact'));
end

end