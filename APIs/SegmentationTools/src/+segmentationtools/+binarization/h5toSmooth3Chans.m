function [cleanIns,cleanOuts,cleanOns] = h5toSmooth3Chans(currSeg,outInOnChans,threshVec,strelRad,spanBool)
%H5TOSMOOTH3CHANS a function specialized for analyzing .h5 segmentations of
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

% Ensure that threshVec is defined for all three channels of interest
if numel(threshVec) == 1
    threshVec = repmat(threshVec,1,3);
end
% Define spanBool if not passed
if nargin < 5
    spanBool = 0;
end

% Instantiate morphological object for trimming
strelObj = strel('sphere',strelRad);

% Threshold probability segmentations of inside and outside channels
outInds = imbinarize(currSeg(:,:,:,outInOnChans(1)),threshVec(1));
inInds = imbinarize(currSeg(:,:,:,outInOnChans(2)),threshVec(2));

% Clean up binarizations and define filtered object ins, outs, and ons
cleanIns = imdilate(imerode(inInds,strelObj),strelObj);
cleanOuts = imdilate(imerode(outInds,strelObj),strelObj) & ~(cleanIns);
if spanBool == 1
    cleanOns = ~(cleanIns | cleanOuts);
elseif spanBool == 0
    onInds = imbinarize(currSeg(:,:,:,outInOnChans(3)),threshVec(3));
    cleanOns = imdilate(imerode(onInds,strelObj),strelObj);
end
    
end

