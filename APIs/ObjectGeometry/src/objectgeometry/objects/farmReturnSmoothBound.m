function [erodedBnd] = farmReturnSmoothBound(segBW,strelRad,ogSize)
%FARMRETURNSMOOTHBOUND Construct and smooth a resized morphological boundary.
% Inputs:
%   segBW       Binary 3D foreground volume.
%   strelRad    Signed spherical radius: positive dilates, otherwise erodes.
%   ogSize      Reference grid dimensions used to calculate a uniform scale.
% Outputs:
%   erodedBnd   Smoothed, thresholded and eroded logical boundary volume.
%
% See also farmReturnSmoothBoundsBW

%2025-04-18 - Rémi Boros

% Generate morpho kernel
strelObj = strel('sphere',abs(strelRad));
segSize = size(segBW);
maxScale = max(ogSize./segSize);
% erode/dilate
if strelRad > 0
    secondMask = imdilate(segBW,strelObj);
    boundaryMat = secondMask - segBW;
else
    secondMask = imerode(segBW,strelObj);
    boundaryMat = segBW - secondMask;
end

% Smooth
scaledBnd = imresize3(boundaryMat,maxScale*segSize);
smoothBnd = imgaussfilt3(scaledBnd,2);
erodedBnd = imerode(imbinarize(smoothBnd,.5),strel('sphere',1));

end


% -------------------------------------------------------------------------
% BEHAVIOR
% -------------------------------------------------------------------------
% Preserves uniform resizing by max(ogSize ./ size(segBW)), followed by
% Gaussian smoothing with sigma=2, thresholding at 0.5 and radius-1 erosion.
% Output dimensions need not equal ogSize when axis scale factors differ.
% imresize3 uses its default interpolation; this is resampling, not axis
% reordering or a registration operation. No physical calibration is inferred.
%
% EXAMPLE
% -------------------------------------------------------------------------
% mask = false(12, 12, 12);
% mask(4:9, 4:9, 4:9) = true;
% boundary = farmReturnSmoothBound(mask, 1, [12 12 12]);
