function [allGrads,distMat] = getDistGrads(fullSegDir,h5Chans,outInOnChans,h5thresh,imgSize,imgScaling,inOnDist)
%GETDISTGRADS This function is predominantly used to save on space. Takes
%in a directory of an h5 file (dir + filename), channels to be sampled (3),
%the order of channels corresponding to drop exteriors, interiors, and
%layer segmentations, a threshold vector to binarize drop segmentations,
%size of the original image used to segment, and a scaling value used to
%rescale the segmentations before splitting into separate pixel classes.
%imgScaling is defined wrt fraction of the original image (e.g. [.5 .5 2]
%corresponds to a final scaling of .5 the original x dimension, .5 the
%original y dimension, and 2 times the original z dimension).
% allGrads is a 4D tensor containing the gradients of the distance
% transforms along x, y, and z (in that order along 4th dimension)
% inOnDist is a boolean used to distinguish whether or not the user wants
% gradients calculated for out-on perimeters only (1) or out-(in+on)
% perimeters (0). Note that the ordering of distMat natively assumes
% row,col convention, meaning that the user is operating in a left-handed
% coordinate system. WE THEREFORE FLIP THE SIGN OF GRADY
% 2023-11-28

% Load the h5
currH5 = loadH5(fullSegDir,'/exported_data',h5Chans);
% Separate into ins, outs, ons
[cleanIns,cleanOuts,cleanOns] = h5toSmooth3Chans(imresize3_4mat(currH5,...
    imgSize.*imgScaling),outInOnChans,h5thresh,1,1);
% Calculate the distance transform
if inOnDist == 1
    distMat = distTransFromBoundary(cleanOns, cleanOuts, cleanIns, 1);
else
    distMat = distTransFromBoundary(cleanOns|cleanIns, cleanOuts, false(size(cleanIns)), 1);
end
% Take the gradient, rescale to image size, then return.
[gradx,grady,gradz] = gradient(distMat);
allGrads = zeros([size(gradx) 3]);
allGrads(:,:,:,1) = gradx; allGrads(:,:,:,2) = -grady; allGrads(:,:,:,3) = gradz;
allGrads = imresize3_4mat(allGrads,imgSize);

end

