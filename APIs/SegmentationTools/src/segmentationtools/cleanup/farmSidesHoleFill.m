function [outMat] = farmSidesHoleFill(inMat)
%FARMSIDESHOLEFILL Patches holes using imfill in logical matrix inMat, taking
%into account "holes" on matrix boundaries. This is done crudely by cycling
%through each dimension of the matrix, padding with 1s, then using imfill
%'holes'. Obviously not suitable for patching objects at corners, nor
%objects with linked/connected topologies.
% 2024-08-13 - Rémi Boros

permVec = 1:(ndims(inMat));
for permInd = 1:numel(permVec)
    permVec = circshift(permVec,1);
    inMat = permute(inMat,permVec);
    padMat = ~padarray(~inMat,[1 0 0]);
    patchedMat = imfill(padMat,'holes');
    inMat = patchedMat(2:(end-1),:,:);
end

outMat = inMat;

end

