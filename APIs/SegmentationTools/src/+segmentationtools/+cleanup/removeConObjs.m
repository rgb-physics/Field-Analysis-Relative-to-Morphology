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

%Apply bwconncomp and regionprops(3)
objInfo = bwconncomp(logicMat);
if numel(size(logicMat)) == 2
    objProps = regionprops(objInfo,"Area");
elseif numel(size(logicMat)) == 3
    objProps = regionprops3(objInfo,"Volume");
end

%Get indices of objects to remove
switch modeStr

    case "large"
        [~,sizeInds] = sort([objProps.Volume]);
        objInds = sizeInds(1:end-toKeep);

    case "indices"
        objInds = ~ismember(toKeep, 1:numel([objProps.Volume]));
    
end

%Remove objects
toRemove = cell2mat([objInfo.PixelIdxList(objInds)]');
logicMat(toRemove) = false;


end

