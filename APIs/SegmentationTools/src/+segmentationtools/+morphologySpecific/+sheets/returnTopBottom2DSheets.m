function [topLayer,botLayer,topLayerZs,botLayerZs, centerSlice,centerSliceZs,splitSlice] = returnTopBottom2DSheets(inputData)
%RETURNTOPBOTTOM2DSHEETS  Takes in a binarized 3D logical stack
%corresponding to binarized data of 2 sheets. The function attempts to
%identify the top and bottom sheets, returning their locations and z
%values. It is assumed that material is 1s and background pixels are 0

%% Get z layer with least protein nearest center
splitSlice = getCentralSlice(inputData);

%% Artifically set "mid" layer to 0
cutData = inputData;
cutData(:,:,(splitSlice-2):(splitSlice+2)) = 0;

%% Get object sizes
bwProps = regionprops3(cutData);
bwObjs = bwconncomp(cutData);

%% Get top and bottom layers
[~, bwOrder] = sort([bwProps.Volume]);

layer1Ind = bwOrder(end);
layer1Pix = cell2mat(bwObjs.PixelIdxList(layer1Ind));
layer1 = zeros(size(cutData));
layer1(layer1Pix) = 1;

layer2Ind = bwOrder(end-1);
layer2Pix = cell2mat(bwObjs.PixelIdxList(layer2Ind));
layer2 = zeros(size(cutData));
layer2(layer2Pix) = 1;

layerStore = false(size(layer1,1),size(layer1,2),size(layer1,3),2);
layerStore(:,:,:,1) = logical(layer1);
layerStore(:,:,:,2) = logical(layer2);

%% Identify top vs bottom layer
[~,~,zMat] = ndgrid(1:size(cutData,1), 1:size(cutData,2), 1:size(cutData,3));

oneInds = (layerStore(:,:,:,1) == 1);
layer1Check = zMat;
layer1Check(~oneInds) = 0;
meanZ1 = sum(layer1Check(layer1Check ~= 0))/numel(layer1Check(layer1Check ~= 0));

oneInds = (layerStore(:,:,:,2) == 1);
layer2Check = zMat;
layer2Check(~oneInds) = 0;
meanZ2 = sum(layer2Check(layer2Check ~= 0))/numel(layer2Check(layer2Check ~= 0));

layerCheckStore = zeros(size(layer2Check,1),size(layer2Check,2),size(layer2Check,3),2);
layerCheckStore(:,:,:,1) = layer1Check;
layerCheckStore(:,:,:,2) = layer2Check;

[~,layerOrder] = sort([meanZ1 meanZ2]);         %Lower z are first planes imaged (represented at "top" of tif); on spinning disk, these usually correspond to the bottom of chamber
topLayer = layerStore(:,:,:,layerOrder(1));
botLayer = layerStore(:,:,:,layerOrder(2));
topLayerZs = layerCheckStore(:,:,:,layerOrder(1));
botLayerZs = layerCheckStore(:,:,:,layerOrder(2));

%% Define center slice of removed data
centerSlice = false(size(inputData));
centerSlice(:,:,(splitSlice-2):(splitSlice+2)) = inputData(:,:,(splitSlice-2):(splitSlice+2));
centerSliceZs = zeros(size(centerSlice));
centerSliceZs(centerSlice) = zMat(centerSlice);

end

