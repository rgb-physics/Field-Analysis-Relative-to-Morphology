function [outVec] = farmCellIndSizes(inCell, desCol)
%FARMCELLINDSIZES Takes in a cell array with indices containing vectors. By
% Inputs:
%   inCell          Cell array whose stored lengths are measured.
%   desCol          Requested cell-array column.
% Outputs:
%   outVec          Lengths of arrays stored in the selected cell column.

if nargin == 1
    desCol = 1;
end

outVec = arrayfun(@(x) numel(inCell{x, desCol}), 1:numel(inCell(:, desCol)));

end

% -------------------------------------------------------------------------
% BEHAVIOR
% -------------------------------------------------------------------------
% FARMCELLINDSIZES Takes in a cell array with indices containing vectors. By
% default, this function can only handle 1 column of a cell at a time. The
% function returns the length of each array stored along the requested
% column.
