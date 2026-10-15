function [ccObj,storeStruct] = farmBlobMat2CCProps(logicMat,reqFields,storeStruct)
%FARMBLOBMAT2CCPROPS Compatible historical per-frame property storage.
% Native properties now use measureObjects, fixing multiple-object 2-D output.
if nargin<3 || isempty(storeStruct), storeStruct = struct(); end
[properties,objects] = farmMeasureObjects(logicMat,reqFields,struct('InputType','mask'));
ccObj = objects.Components;
if isempty(fieldnames(storeStruct)), currInd = 1; else, currInd = numel(storeStruct)+1; end
names = properties.Properties.VariableNames;
names = setdiff(names,{'DatasetID','Frame','ObjectID'},'stable');
for i = 1:numel(names), storeStruct(currInd).(names{i}) = properties.(names{i}); end
end
