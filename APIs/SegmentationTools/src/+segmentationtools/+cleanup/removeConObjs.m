function [logicMat,toRemove] = removeConObjs(logicMat,toKeep,modeStr)
%REMOVECONOBJS Takes in a matrix. Using bwconncomp and regionprops(3),
%the function removes specific connected bodies, depending on the selected
%mode. This function is designed for binarized logic matrices as input
%   MODES:
%           - "large":  (default) removes all but TOKEEP objects. 
%                       Eg. TOKEEP = 2, remove all but 2 largest objs
%           - "indices": Removes all objs but those with indices stored in
%                        TOKEEP
% Rémi Boros

%Set cases if undefined
if nargin == 1
    toKeep = 1;
    modeStr = "large";
elseif nargin == 2
    modeStr = "large";
end

% Apply connected-component analysis. Component voxel counts work for both
% 2-D and 3-D inputs and avoid switching between Area and Volume fields.
objInfo = bwconncomp(logicMat);
objSizes = cellfun(@numel, objInfo.PixelIdxList);

%Get indices of objects to remove
switch modeStr

    case "large"
        validateattributes(toKeep, {'numeric'}, ...
            {'real','finite','scalar','integer','nonnegative'}, ...
            mfilename, 'toKeep');
        [~,sizeInds] = sort(objSizes);
        numToRemove = max(0, objInfo.NumObjects - double(toKeep));
        objInds = sizeInds(1:numToRemove);

    case "indices"
        validateattributes(toKeep, {'numeric'}, ...
            {'real','finite','vector','integer','positive'}, ...
            mfilename, 'toKeep');
        objInds = find(~ismember(1:objInfo.NumObjects, toKeep));

    otherwise
        error('segmentationtools:InvalidRemovalMode', ...
            'modeStr must be "large" or "indices".');
    
end

%Remove objects
toRemove = vertcat(objInfo.PixelIdxList{objInds});
logicMat(toRemove) = false;


end

