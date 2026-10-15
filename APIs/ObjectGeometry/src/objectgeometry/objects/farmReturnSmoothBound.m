function [erodedBnd] = farmReturnSmoothBound(segBW,strelRad,ogSize)
%FARMRETURNSMOOTHBOUND Generate a perimeter at interfaces of objects in a
%binarized image ogBW. The perimeter is made approximately smooth in a
%matrix of different size, optionally, than the original binarized image.
%Useful for distance transform in cubic voxels, then defining perimeters in
%image with different/rescaled voxel representation.
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

