function [outData] = imbinarize3_4D(inData,threshVals)
%IMBINARIZE3_4D Iterates through fourth dimension, applying thresholds to
%each 3D matrix using imbinarize

% Extend threshold vector if 1D
if numel(threshVals) < size(inData,4)
    threshVals = repmat(threshVals, 1, size(inData,4));
end

% Instantiate output matrix
outData = zeros(size(inData));
% Resize each 3D matrix
for index = 1:size(inData,4)
    outData(:,:,:,index) = imbinarize(inData(:,:,:,index),threshVals(index));
end

outData = logical(outData);
end

