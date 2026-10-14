function [scaleInds] = rescaleCoords_Inds(inputInds,ogDims,newDims)
%RESCALECOORDS_INDS Take in indices corresponding to coordinates in a
%matrix with size ogDims. Return indices of corresponding coordinates in a
%matrix with size newDims. 
% 2025-04-21 - Rémi Boros

if numel(ogDims) == 3
    [censRows,censCols,censDepths] = ind2sub(ogDims,inputInds);
    scaleCoords = rescaleCoords([censCols censRows censDepths], ogDims, newDims);
    scaleInds = sub2ind(newDims,scaleCoords(:,2),scaleCoords(:,1),scaleCoords(:,3));
elseif numel(ogDims) == 2
    [censRows,censCols] = ind2sub(ogDims,inputInds);
    scaleCoords = rescaleCoords([censCols censRows], ogDims, newDims);
    scaleInds = sub2ind(newDims,scaleCoords(:,2),scaleCoords(:,1));
end

end

