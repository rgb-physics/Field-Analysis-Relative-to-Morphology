function [gaussStore] = generateGaussCorrectionPerZ(layerStore, outlierSigma, gKernel, mKernel, lKernel)
%GENERATEGAUSSCORRECTIONPERZ This function generates a 3D matrix of
%gaussian background arrays used to divide out inhomogenous illumination
%profiles. LAYERSTORE is a 3D array of images with dimensions [x,y,z].
%The function uses the tophat function/Ricker wavelet with a kernel size
%LKERNEL to remove outlying bright spots in the stacks, replacing them with
%values approximated from the median of the local neighborhood MKERNEL 
%(in x and y). Each z slice is then smoothed through gaussian convolution,
%using a gaussian with kernel GKERNEL. BRIGHTTHRESH determines the
%threshold value above which bright pixels are removed

%Get matrix dimensions
storeDims = size(layerStore);

%Intensity per layer over time
meanProj = squeeze(mean(layerStore,4));     %convert to one gaussian per z layer

%Tophat filter for outliers
gradsMat = LOG(meanProj,lKernel);
botThresh = mean(gradsMat(:)) - outlierSigma*std(gradsMat(:));
topThresh = mean(gradsMat(:)) + outlierSigma*std(gradsMat(:));

%Use local median to replace bright outliers
outlierInds = ~((gradsMat > botThresh) & (gradsMat < topThresh));
localMedMat = movmedian(movmedian(movmedian(meanProj,mKernel,1),mKernel,2),mKernel,3);
corrMat = meanProj;
corrMat(outlierInds) = localMedMat(outlierInds);

%Generate gaussians
gaussStore = zeros(storeDims(1), storeDims(2),storeDims(3));
for currZ = 1:storeDims(3)
    gaussStore(:,:,currZ) = imgaussfilt(double(corrMat(:,:,currZ)), gKernel);
end

end

