function [landtype] = CFTReorderLandType(lt, LandOrder)

s=struct2cell(lt);
%t=struct2cell(LandOrder);

for i =1:length(LandOrder)
	loc(i)=find(strcmp(s(2,1,i),LandOrder));
end

for i =1:length(LandOrder)
	landtype(i)=lt(loc(i));
end

end
