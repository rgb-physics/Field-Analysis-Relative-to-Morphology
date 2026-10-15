function [cleanIns,cleanOuts,cleanOns] = farmH5toSmooth3Chans(currSeg,outInOnChans,threshVec,strelRad,spanBool)
%FARMH5TOSMOOTH3CHANS a function specialized for analyzing .h5 segmentations of
%three channels of differentiation on structures that can approximately be
%considered to have an "inside," and "outside," and a separating "layer"
% The script takes in a matrix of the form [row,col,depth,channel] in
% CURRSEG, the order of outside, inside, and layer channels in
% OUTINONCHANS, a vector of thresholds as cutoffs for each probability
% field in CURRSEG corresponding to each channel (THRESHVEC), and a radius
% used for morphological operations for removing noise. Optionally, the
% user can specify whether or not the three given channels ar meant to span
% the entire space (SPANBOOL). Doing so determines whether or not to fill
% "over-trimmed" voxels into the layer channel.
% 2023/10/18
% Compatibility wrapper added 2026-10-10. New code should call
% farmSmoothInOnOutProbabilities, whose channel
% and output order is [inside, wall, outside]. This wrapper retains the
% historical OUTINONCHANS input order [outside, inside, wall] and outputs
% [inside, outside, wall].

if nargin < 5
    spanBool = 0;
end
if isscalar(threshVec)
    threshVec = repmat(threshVec, 1, 3);
end
semanticChannels = outInOnChans([2 3 1]);
semanticThresholds = threshVec([2 3 1]);
options = struct('OpeningRadius', strelRad, ...
    'SpanSpace', logical(spanBool));
[cleanIns, cleanOns, cleanOuts] = ...
    farmSmoothInOnOutProbabilities( ...
    currSeg, semanticChannels, semanticThresholds, options);
end

