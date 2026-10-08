function [layerStore] = generate4DLayerStore_ZandT(dataDir,dataNameForm,selectZs,selectTs)
%GENERATE4DLAYERSTORE_ZANDT Generates a 4D tiff of desired z and t slices
%of all x and y from 3D tiffs stored in dataDir with name format
%dataNameForm over a range of selected z and t values stored in vectors
%selectZs and selectTs

dataName = sprintf(dataNameForm, selectTs(1));
currData = imread(fullfile(dataDir, dataName), 1);
layerStore = zeros(size(currData,1), size(currData,2), numel(selectZs), numel(selectTs));
%Iterate over times and get all 2D tiffs of interest in 4D matrix
for currT = 1:numel(selectTs)
    dataName = sprintf(dataNameForm, selectTs(currT));
    layerStore(:,:,:,currT) = getLayersOverTimeFrom3DTif(dataDir, dataName, selectZs);
end

end

