function [outVec] = farmStructLenVec(inStruct, desField)
%FARMSTRUCTLENVEC Takes in a structure inStruct with a field called
% Inputs:
%   inStruct        Input structure containing the requested fields.
%   desField        Name of the structure field used for repetition counts.
% Outputs:
%   outVec          Structure indices repeated according to the selected field lengths.

lenVec = farmStructFieldSizes(inStruct, desField);
cellRepVec = arrayfun(@(x) repmat(x, lenVec(x), 1), 1:numel(inStruct), 'UniformOutput', false);
outVec = vertcat(cellRepVec{:});

end

% -------------------------------------------------------------------------
% BEHAVIOR
% -------------------------------------------------------------------------
% FARMSTRUCTLENVEC Takes in a structure inStruct with a field called
% desField (a string), returning a vector of the structure index repeated a
% number of times corresponding to the number of objects at that index in
% the field. ( [1 1 1 1 2 2 3 3 3 4 5 5 5] for a five index structure in
% which is contained 5, 2, 3, 1, and 3 objects, respectively
