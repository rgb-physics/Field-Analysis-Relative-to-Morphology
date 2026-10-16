function [outData] = farmImbinarize3_4D(inData, threshVals)
%FARMIMBINARIZE3_4D Apply a threshold to each fourth-dimension volume.
% Inputs:
%   inData       Image array in YXZC order.
%   threshVals   Scalar threshold or thresholds indexed by channel.
% Outputs:
%   outData      Logical thresholded array with the input dimensions.
%
% See also imbinarize, farmThresholdProbabilityGroup

% Preserve the original repetition rule for short threshold inputs.
if numel(threshVals) < size(inData, 4)
    threshVals = repmat(threshVals, 1, size(inData, 4));
end

% Instantiate output matrix
outData = zeros(size(inData));

% Threshold each volume independently; no resizing is performed.
for index = 1:size(inData, 4)
    outData(:, :, :, index) = imbinarize(inData(:, :, :, index), threshVals(index));
end


outData = logical(outData);
end


% -------------------------------------------------------------------------
% BEHAVIOR
% -------------------------------------------------------------------------
% If numel(threshVals) < size(inData, 4), the whole threshold input is
% repeated horizontally size(inData, 4) times, then linearly indexed.
% This is not a requirement that only a scalar may be expanded; the original
% short-vector behavior is retained. Extra thresholds are not consumed.
% Threshold interpretation and numeric-type handling follow imbinarize.
% A double temporary output is allocated before conversion to logical.
%
% EXAMPLE
% -------------------------------------------------------------------------
% data = cat(4, [0.2 0.8; 0.5 0.6], [0.7 0.1; 0.4 0.9]);
% masks = farmImbinarize3_4D(data, [0.5 0.6]);
