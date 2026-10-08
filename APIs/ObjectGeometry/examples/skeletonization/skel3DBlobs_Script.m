% Load blob .tifs, extract 3D skeletons through manipulation of the
% distance transform.
% Uses external dependency to calculate gaussian derivatives:
% https://www.mathworks.com/matlabcentral/fileexchange/19696-gaussdiff
% Rémi Boros - 2026-01-27

% dataDir = '<redacted original absolute path>';
dataDir = 'Session 88, Exp 1';
dataName = 'E1_T%03i_trajIDs.tif';

selTimes = 30;
% images will be rescaled s.t. voxel dimensions are equal prior to
% calculating EDT. Tifs will be downscaled to match largest dimension
voxDims = [1.5 1.5 1.5];    
rsPost = 2;
rsFactor = voxDims/max(voxDims)*rsPost;
voxLen = max(voxDims);
% sigma for gaussian derivatives
sigma = 1*rsPost;
gradCut = .5;
% Use Hessian to search for lines?
hBool = 0;

%% Iterate over time points, skeletonize blobs
for tInd = 1:numel(selTimes)
    currT = selTimes(tInd);
    % Load
    loadLabels = tiffreadVolume(fullfile(dataDir,sprintf(dataName,currT)));
    % Rescale to have cubic voxels, if needed
    if prod(rsFactor) ~= 1
        ogLabs = loadLabels;
        loadLabels = imresize3(loadLabels,round(size(loadLabels).*rsFactor));
    end
    if tInd == 1
        matSize = size(loadLabels);
        bndBox = padarray(ones(matSize-round(2*rsPost)),round([1 1 1]*rsPost),'both');
    end
    
    [validCores,coreMat] = skel3DBlobs(loadLabels,gradCut,sigma,hBool);

end


