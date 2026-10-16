function [outVec] = farmGenLenVec(contentsVec, repVec)
%FARMGENLENVEC Repeat supplied values by their corresponding counts.
% Inputs:
%   contentsVec     Values to repeat.
%   repVec          Repetition counts corresponding to contentsVec.
% Outputs:
%   outVec          Values repeated by their corresponding counts.

cellRepVec = arrayfun(@(x) repmat(contentsVec(x), repVec(x), 1), 1:numel(contentsVec), 'UniformOutput', false);
outVec = vertcat(cellRepVec{:});

end

% -------------------------------------------------------------------------
% BEHAVIOR
% -------------------------------------------------------------------------
% FARMGENLENVEC outVec in a vector of integers repVec and a vector of doubles contentsVec.
% Returns a vector wherein each element in contentsVec is repeated the
% number of times indicated in the corresponding index of repVec.
% Rémi Boros - 2024-08-16+; 2024-11-20 SWAPPED repVec and contentsVec
