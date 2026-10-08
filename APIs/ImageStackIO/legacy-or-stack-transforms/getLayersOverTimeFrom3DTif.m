function [layerStore] = getLayersOverTimeFrom3DTif(dataDir, dataName, zSlices)
%GETLAYERSOVERTIMEFROM3DTIF Looks through dataDir for all 3D tifs
%with name dataNameFormat and returns a 3D tif of all (x,y) indices stored
%at desired zSlices.

%% Iterate for each z slice
%Instantiate storage matrices
currTiff = imread(fullfile(dataDir,dataName),1);
layerStore = uint16(zeros(size(currTiff,1), size(currTiff,2), numel(zSlices)));

%Iterate
for currZ = 1:numel(zSlices)
    layerStore(:,:,currZ) = imread(fullfile(dataDir, dataName), zSlices(currZ));
end

end

