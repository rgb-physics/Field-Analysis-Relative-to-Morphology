function [bbStruct] = filBackBonesND(CoMs,lens,direcs)
%FILBACKBONESND Take in filament centers of mass, directors, and lengths.
%Return backbones that pass through each center of mass of appropriate
%lengths. All quantities are expected in row form, ie each column
%corresponds to a different filament. Eg CoMs is DxN, for N filaments.
% direcs are unit vectors in same dimension order as CoMs
% 2025-04-18 -Rémi Boros

numDims = size(CoMs,1);
bbStruct = struct();

plusMinShfts = (lens/2).*[direcs; -direcs];
allBBs = repmat(CoMs,2,1) + plusMinShfts;
for index = 1:numDims
    bbStruct(index).BBs = allBBs(index:numDims:end,:);
end

end

