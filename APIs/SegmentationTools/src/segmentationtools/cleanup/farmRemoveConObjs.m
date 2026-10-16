function [logicMat, toRemove] = farmRemoveConObjs(logicMat, toKeep, modeStr)
%FARMREMOVECONOBJS Retain selected connected foreground components.
% Inputs:
%   logicMat   Binary foreground matrix or volume.
%   toKeep     Component count in 'large' mode (default 1), or component
%              index vector in 'indices' mode.
%   modeStr    'large' (default) or 'indices'.
% Outputs:
%   logicMat   Input array with removed component voxels set to false.
%   toRemove   Linear indices of the removed voxels.
%
% See also bwconncomp

% Rémi Boros

% Use the historical largest-component defaults when arguments are omitted.
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

% Select components to remove using the original component ordering.
switch modeStr

    case "large"
        validateattributes(toKeep, {'numeric'}, ...
            {'real','finite','scalar','integer','nonnegative'}, ...
            mfilename, 'toKeep');
        [~, sizeInds] = sort(objSizes);
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

% Set only the removed components to background.
toRemove = vertcat(objInfo.PixelIdxList{objInds});
logicMat(toRemove) = false;


end


% -------------------------------------------------------------------------
% BEHAVIOR
% -------------------------------------------------------------------------
% 'large' retains at most toKeep largest components by voxel count. Zero
% removes all components; counts exceeding the component count remove none.
% Tied sizes follow MATLAB's sort ordering. 'indices' refers to positions in
% bwconncomp.PixelIdxList, not persistent ObjectIDs or input label values.
% Uses bwconncomp's default connectivity. No physical-volume weighting occurs.
%
% EXAMPLES
% -------------------------------------------------------------------------
% largest = farmRemoveConObjs(mask);
% twoLargest = farmRemoveConObjs(mask, 2);
% [selected, removed] = farmRemoveConObjs(mask, [1 3], "indices");

