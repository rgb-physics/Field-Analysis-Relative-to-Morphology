function [outVec] = farmCellIndSizes(inCell,desCol)
%FARMCELLINDSIZES Takes in a cell array with indices containing vectors. By
%default, this function can only handle 1 column of a cell at a time. The
%function returns the length of each array stored along the requested
%column.

if nargin == 1
    desCol = 1;
end

outVec = arrayfun( @(x) numel(inCell{x,desCol}), 1:numel(inCell(:,desCol)));

end

