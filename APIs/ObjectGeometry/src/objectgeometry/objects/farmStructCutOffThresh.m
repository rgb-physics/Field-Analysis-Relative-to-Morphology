function [newStruct] = farmStructCutOffThresh(inStruct, choiceField, minCut, maxCut, changeFields)
%FARMSTRUCTCUTOFFTHRESH Structure is constructed based on whether or not the
%field "choiceField" falls between minCut and maxCut. choiceField is a
%string, inStruct a structure, minCut and maxCut numbers. changeFields is a
%cell array of field names (strings) over which to iterate and replace
%values of

% Check to see if fields to change were passed
if nargin == 4
    changeFields = {'Vol','Cens'};
end

% Get all values stored in structure (assumes "orthogonal" dimensionality is
% identical for each index)
allFieldVals = vertcat(inStruct.(choiceField));

% Get inds of volumes in requested threshold
maxDim = numel(size(allFieldVals));
selBoundInds = allFieldVals > minCut & allFieldVals < maxCut;
selBoundInds = (sum(selBoundInds,2:maxDim) == size(selBoundInds,2:maxDim));   % logical and along second dimension

% Generate index vectors to keep track of object and index IDs
structSize = numel(inStruct);
numPerInd = farmStructFieldSizes(inStruct,choiceField);
if maxDim > 1
    numPerInd = numPerInd/prod(size(allFieldVals,2:maxDim));    % Scale by the number of elements along each "orthogonal" dimension
end
idVec = cell2mat(arrayfun( @(x) 1:numPerInd(x), 1:structSize, 'UniformOutput', false));
indVec = cell2mat(arrayfun( @(x) repmat(x, 1, numPerInd(x)), 1:structSize, 'UniformOutput', false));

% Generate new structure with updated selected fields
newStruct = inStruct;
for currInd = 1:structSize

    % Indices of current 
    currInds = (indVec == currInd) & selBoundInds';
    %Iterate through fields
    for fieldInd = 1:numel(changeFields)
        currField = changeFields{fieldInd};
        currFieldAll = vertcat(inStruct.(currField));
        newStruct(currInd).(currField) = currFieldAll(currInds,:);
    end
    %Store IDs of kept objects
    newStruct(currInd).ogIDs = idVec(currInds);

end

end

