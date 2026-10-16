function [outMat] = farmSidesHoleFill(inMat)
%FARMSIDESHOLEFILL Fill side-open holes using the historical padding sequence.
% Inputs:
%   inMat    Logical foreground volume.
% Outputs:
%   outMat   Filled selection after axis permutation and padded hole filling.
%
% See also imfill

% 2024-08-13 - Rémi Boros

permVec = 1:(ndims(inMat));

% Follow the original axis sequence, padding the first current dimension.
for permInd = 1:numel(permVec)
    permVec = circshift(permVec, 1);
    inMat = permute(inMat, permVec);
    padMat = ~padarray(~inMat, [1 0 0]);
    patchedMat = imfill(padMat, 'holes');
    inMat = patchedMat(2:(end-1), :, :);
end

outMat = inMat;

end


% -------------------------------------------------------------------------
% BEHAVIOR
% -------------------------------------------------------------------------
% Foreground padding temporarily closes openings on selected image sides.
% imfill(..., 'holes') fills enclosed background before padding is removed.
% This is not a general repair for corner openings or connected topologies.
% The original permutation sequence is preserved. For 2D arrays it transposes
% the spatial layout; do not assume a general 2D axis-preserving operation.
%
% EXAMPLE
% -------------------------------------------------------------------------
% mask = false(12, 12, 12);
% mask(3:10, 3:10, 3:10) = true;
% mask(5:8, 5:8, 5:8) = false;
% filled = farmSidesHoleFill(mask);

