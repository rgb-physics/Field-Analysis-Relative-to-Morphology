function [outVec] = farmGenLenVec(contentsVec,repVec)
%FARMGENLENVEC outVec in a vector of integers repVec and a vector of doubles contentsVec. 
% Returns a vector wherein each element in contentsVec is repeated the 
% number of times indicated in the corresponding index of repVec.
% Rémi Boros - 2024-08-16+; 2024-11-20 SWAPPED repVec and contentsVec

cellRepVec = arrayfun( @(x) repmat(contentsVec(x), repVec(x), 1), 1:numel(contentsVec), 'UniformOutput', false);
outVec = vertcat(cellRepVec{:});

end

