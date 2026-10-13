function [ccObj,storeStruct] = blobMat2CCProps(logicMat,reqFields,storeStruct)
%BLOBMAT2CCPROPS Takes in a logical matrix, returns connected component
%structure and structure of requested regionproperties. If storeStruct is
%passed, updates storeStruct by appending values to struct end. reqFields
%is a cell of strings representing different fields from regionprops(3)

% Instantiate structure, if needed, and current index
if nargin == 2
    storeStruct = struct();
end
if isempty(fieldnames(storeStruct))
    currInd = 1;
else
    currInd = numel(storeStruct) + 1;
end

% Get region properties
ccObj = bwconncomp(logicMat);

if numel(size(logicMat)) == 3
    currProps = regionprops3(ccObj,reqFields);
elseif numel(size(logicMat)) == 2
    currProps = regionprops(ccObj,reqFields);
end

% Store in structure
for fieldInd = 1:numel(reqFields)
    currField = reqFields{fieldInd};
    storeStruct(currInd).(currField) = currProps.(currField);
end

end


