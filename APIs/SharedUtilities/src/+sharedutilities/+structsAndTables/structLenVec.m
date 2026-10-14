function [outVec] = structLenVec(inStruct,desField)
%STRUCTLENVEC Takes in a structure inStruct with a field called
% desField (a string), returning a vector of the structure index repeated a
% number of times corresponding to the number of objects at that index in
% the field. ( [1 1 1 1 2 2 3 3 3 4 5 5 5] for a five index structure in
% which is contained 5, 2, 3, 1, and 3 objects, respectively

lenVec = sharedutilities.structsAndTables.structFieldSizes(inStruct,desField);
cellRepVec = arrayfun( @(x) repmat(x, lenVec(x), 1), 1:numel(inStruct), 'UniformOutput', false);
outVec = vertcat(cellRepVec{:});

end

