function [allGrads, distMat] = farmGetDistGrads(fullSegDir, h5Chans, outInOnChans, h5thresh, imgSize, imgScaling, inOnDist)
%FARMGETDISTGRADS This function is predominantly used to save on space. Takes
% Inputs:
%   fullSegDir      Full HDF5 segmentation filename, including its folder.
%   h5Chans         Stored probability channels to load.
%   outInOnChans    Semantic channel positions in outside/inside/wall order.
%   h5thresh        Probability thresholds corresponding to the semantic channels.
%   imgSize         Original spatial image dimensions.
%   imgScaling      Requested spatial scale factors.
%   inOnDist        Historical selector controlling the distance-reference regions.
% Outputs:
%   allGrads        Distance derivatives with XYZ components in dimension 4.
%   distMat         Historical signed-distance reference field.

% Load the h5
image = farmReadH5(fullSegDir, '/exported_data', struct('SourceAxes', 'CXYZ', 'Channels', h5Chans));
currH5 = squeeze(image.Data); % Preserve the original loader's default YXZC arrangement.
% Separate into ins, outs, ons
[cleanIns, cleanOuts, cleanOns] = farmH5toSmooth3Chans(farmImresize3_4mat(currH5, ...
                                                                        imgSize .* imgScaling), outInOnChans, h5thresh, 1, 1);
% Calculate the distance transform
if inOnDist == 1
    distMat = farmDistTransFromBoundary(cleanOns, cleanOuts, cleanIns, 1);
else
    distMat = farmDistTransFromBoundary(cleanOns | cleanIns, cleanOuts, false(size(cleanIns)), 1);
end
% Take the gradient, rescale to image size, then return.
allGrads = farmDistanceGradients(distMat, struct('FlipY', true));
allGrads = farmImresize3_4mat(allGrads, imgSize);

end

% -------------------------------------------------------------------------
% BEHAVIOR
% -------------------------------------------------------------------------
% FARMGETDISTGRADS This function is predominantly used to save on space. Takes
% in a directory of an h5 file (dir + filename), channels to be sampled (3),
% the order of channels corresponding to drop exteriors, interiors, and
% layer segmentations, a threshold vector to binarize drop segmentations,
% size of the original image used to segment, and a scaling value used to
% rescale the segmentations before splitting into separate pixel classes.
% imgScaling is defined wrt fraction of the original image (e.g. [.5 .5 2]
% corresponds to a final scaling of .5 the original x dimension, .5 the
% original y dimension, and 2 times the original z dimension).
% allGrads is a 4D tensor containing the gradients of the distance
% transforms along x, y, and z (in that order along 4th dimension)
% inOnDist is a boolean used to distinguish whether or not the user wants
% gradients calculated for out-on perimeters only (1) or out-(in+on)
% perimeters (0). Note that the ordering of distMat natively assumes
% row,col convention, meaning that the user is operating in a left-handed
% coordinate system. WE THEREFORE FLIP THE SIGN OF GRADY
% 2023-11-28
