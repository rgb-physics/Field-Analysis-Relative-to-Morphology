function [outKs] = genScaledKVec(dimSize,dimdx)
%GENSCALEDKVEC Takes in a vector length (dimension length) and returns a
%vector of ks for use in conjunction with FFT. dimSize must be a scalar
% Rémi Boros - 2024-01-29

if nargin == 1
    dimdx = 1;
end

% Generate reference and index vectors
accessInds = fftshift(0:dimSize - 1) + 1;
refVec = genReflVec(dimSize);
% Generate vector of k indices
KInds = refVec(accessInds) + 1;
KInds((floor(end/2)+1):end) = KInds((floor(end/2)+1):end) - 1;
% Rescale Ks
outKs = KInds/(dimSize*dimdx);
%Flip sign of First half of Ks
outKs(1:floor(numel(outKs)/2)) = -outKs(1:floor(numel(outKs)/2));

end

