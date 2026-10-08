function [gaussFilt3D,avgBleach,layerStore] = generateGaussCorrectionMaskPerZ_3DTiff(dataDir, dataNameForm, selectTimes, zSlices, gKernel, rollingWin, saveBool, saveDir, acSaveName)
%GENERATEGAUSSCORRECTIOMASKPERZ_3DTIFF This function cycles through a series of
%tifs stored in DATADIR with name DATANAME over a series of times
%SELECTTIMES and returns a Gaussian mask used to correct for correction of
%intensity across xy. This is done over a desired selection of z values (in
%indices) via Gaussian smoothing with sigma GKERNEL. Bleach correction is
%taken into account over time by looking at the average intensity of each
%layer over time and averaging these values with a rolling average of
%window size ROLLINGWIN

if nargin < 7
    saveBool = 0;
end

%% 
layerStore = generate4DLayerStore_ZandT(dataDir,dataNameForm,zSlices,selectTimes);
gaussStore = uint16(zeros(size(layerStore,1), size(layerStore,2),numel(zSlices)));

 %%Apply gaussian blur
meanProj = squeeze(mean(layerStore,4));     %convert to one gaussian per z layer
for currZ = 1:numel(zSlices)
    gaussStore(:,:,currZ) = imgaussfilt(double(meanProj(:,:,currZ)), gKernel);
end

% Average bleach rate info over Z
bleachInfo = squeeze(median(median(layerStore,1),2));
avgBleach = movmean(mean(bleachInfo,1),rollingWin)';

%Generate matrix of gaussians
medianGauss = mean(gaussStore,3);
scalingMat = permute(repmat(avgBleach, [ 1 size(medianGauss,1) size(medianGauss,2)]),[2 3 1]);
normScalingMat = scalingMat/(max(scalingMat(:)));
gaussFilt3D = uint16((repmat(medianGauss,[1 1 numel(avgBleach)])).*normScalingMat);

%% Save if desired
if saveBool == 1
    %Iterate through slices and save
    for currSlice = 1:size(gaussFilt3D,3)
        currPath = fullfile(saveDir, sprintf(acSaveName, currSlice));
        imwrite(gaussFilt3D(:,:,currSlice),currPath);
    end
    
    %Save 3D stack
    save3DTiff(gaussFilt3D, fullfile(saveDir, "allSlices.tif"));
end

end


