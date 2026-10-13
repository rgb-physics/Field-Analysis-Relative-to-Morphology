function [validCores,coreMat] = skel3DBlobs(inMat,gradCut,sigma,hBool)
%SKEL3DBLOBS 
% Load blob .tifs, extract 3D skeletons through manipulation of the
% distance transform.
% Uses external dependency to calculate gaussian derivatives:
% https://www.mathworks.com/matlabcentral/fileexchange/19696-gaussdiff
% Rémi Boros - 2026-01-27

if exist('gfilter','file') ~= 2
    error('objectgeometry:MissingGaussianDerivative','skel3DBlobs requires the historical gaussdiff gfilter dependency.');
end
% Generate variables and matrices for analysis/tasks
matSize = size(inMat);
bndBox = padarray(ones(matSize-2),[1 1 1],'both');

% Calculate euclidian distance transform (EDT)
bwMat = logical(inMat);
distMat = bwdist(~bwMat);
blobBndFilt = imerode(bwMat,strel('sphere',sigma));

% Calculate 3D grad of EDT, then define scalar field from 3D grad maxima
dxL = gfilter(distMat,sigma,[0 1 0]);
dyL = gfilter(distMat,sigma,[1 0 0]);
dzL = gfilter(distMat,sigma,[0 0 1]);
maxGrads = max(max(abs(dxL),abs(dyL)),abs(dzL));
% Remove erroneous zero-gradients at image boundaries
maxGrads = (maxGrads + sharedutilities.arrays.consMatLnB(ones(matSize),~bwMat)).*bndBox  + (1-bndBox);

% Isolate voxels that are candidates for blob cores
coreMat = sharedutilities.arrays.consMatLnB(maxGrads < gradCut,blobBndFilt);
% Remove eroneous detections at drop boundaries
if floor(sigma/2) > 0
    coreMat = imerode(coreMat,strel('sphere',round(sigma/2)));
end
% Apply Hessian to further refine points?
if hBool == 0
    validCores = find(coreMat);
else
    candInds = find(coreMat);
    % Calculate Hessian of EDT using gaussian derivative
    % Second derivatives
    dxxL = gfilter(distMat,3*sigma,[0 2 0]);
    dyyL = gfilter(distMat,3*sigma,[2 0 0]);
    dzzL = gfilter(distMat,3*sigma,[0 0 2]);
    dxyL = gfilter(distMat,3*sigma,[1 1 0]);
    dxzL = gfilter(distMat,3*sigma,[0 1 1]);
    dyzL = gfilter(distMat,3*sigma,[1 0 1]);
    % Get eigenvalues of Hessian at candidates
    eVals = zeros(numel(candInds), 3);
    tic
    % Iterate through candidate points, calculate eigenvalues
    for index = 1:numel(candInds)
        voxelIndex = candInds(index);
        currH = [dyyL(voxelIndex) dxyL(voxelIndex) dyzL(voxelIndex); ...
                 dxyL(voxelIndex) dxxL(voxelIndex) dxzL(voxelIndex); ...
                 dyzL(voxelIndex) dxzL(voxelIndex) dzzL(voxelIndex) ];
        eVals(index,:) = eig(currH)';
    end
    toc
    % Select points where e1 >> e2,e3; that is, local structure is line-like
    % eigenAspectRatios = eVals(:,1)./max(eVals(:,2:3),[],2);
    % linesFilt = abs(eigenAspectRatios)>2;
    eigenAspectRatios2 = max(eVals,[],2)./eVals;
    linesFilt2 = max(abs(eigenAspectRatios2),[],2)>2;
    % Retrieve valid subset of coordinates
    validCores = candInds(linesFilt2);
    coreMat = sharedutilities.arrays.consMatLnB(ones(matSize),validCores);
end

end

