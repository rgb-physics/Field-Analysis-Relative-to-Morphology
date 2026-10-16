function [cleanIns, cleanOuts, cleanOns] = farmH5toSmooth3Chans(currSeg, outInOnChans, threshVec, strelRad, spanBool)
%FARMH5TOSMOOTH3CHANS Preserve the historical three-category smoothing interface.
% Inputs:
%   currSeg        Loaded probability array in YXZC order, not an HDF5 path.
%   outInOnChans   Channel indices in [outside, inside, wall] order.
%   threshVec      Scalar threshold or three thresholds in that same order.
%   strelRad       Morphological opening radius in voxels.
%   spanBool       Optional coverage flag; defaults to 0.
% Outputs:
%   cleanIns       Cleaned inside mask.
%   cleanOuts      Cleaned outside mask.
%   cleanOns       Cleaned wall mask.
%
% See also farmSmoothInOnOutProbabilities, farmReadH5

% 2023/10/18
% Compatibility wrapper added 2026-10-10.

if nargin < 5
    spanBool = 0;
end

if isscalar(threshVec)
    threshVec = repmat(threshVec, 1, 3);
end

% Reorder the historical outside/inside/wall inputs for the current consumer.
semanticChannels = outInOnChans([2 3 1]);
semanticThresholds = threshVec([2 3 1]);
options = struct('OpeningRadius', strelRad, ...
    'SpanSpace', logical(spanBool));

% Restore the historical inside/outside/wall output argument order.
[cleanIns, cleanOns, cleanOuts] = ...
    farmSmoothInOnOutProbabilities( ...
    currSeg, semanticChannels, semanticThresholds, options);
end


% -------------------------------------------------------------------------
% BEHAVIOR
% -------------------------------------------------------------------------
% Does not load files. The called smoothing operation thresholds probability
% channels strictly and opens each mask by erosion followed by dilation.
% With spanBool enabled, wall is the complement of cleaned inside/outside.
% Without it, wall is processed independently; masks may overlap.
% For new callers, farmSmoothInOnOutProbabilities uses the explicit
% inside/wall/outside input and output order. This wrapper retains its
% different historical channel, threshold and output ordering.
%
% EXAMPLE
% -------------------------------------------------------------------------
% probabilities = zeros(8, 8, 3, 3);
% probabilities(:, :, :, 1) = 0.8; % stored inside channel
% [inside, outside, wall] = farmH5toSmooth3Chans( ...
%     probabilities, [3 1 2], 0.5, 0, false);
%
% UNITS AND COORDINATES
% -------------------------------------------------------------------------
% Channel indices address dimension 4. Opening radius uses voxel units;
% there is no spatial resampling or intensity normalization here.
