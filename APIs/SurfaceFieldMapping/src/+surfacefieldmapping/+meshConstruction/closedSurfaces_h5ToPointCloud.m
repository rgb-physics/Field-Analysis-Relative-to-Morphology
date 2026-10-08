%% A first pass on how to extract surfaces of roughly drop-like objects
% Ideally, this is will iterate through .h5s, then return point clouds
% corresponding to the drop surfaces. Finally, these point clouds are
% converted into mesh objects
% 10/02/2023 - 10/03/2023
%% Data info
% baseDir = '<redacted original absolute path>';
baseDir = 'Session 45, Exp 3';
segDir = fullfile(baseDir,'7 Ilastik Training\Second Pass - 2');
segName = 'PassOne_t%03i_16bitSubSamp_Probabilities.h5';
ptDir = fullfile(baseDir, '10 Point Clouds');       mkdir(ptDir);
meshDir = fullfile(baseDir, '11 Mesh Objects Poisson 1');     mkdir(meshDir);
ptName = 'Time%03i_pointCloud.ply';
meshName = 'Time%03i_meshObjs.ply';
% meshLabDir = '<redacted original absolute path>';
meshLabDir = '';
ply2Mesh = 'batch_pointCloud2Mesh - MATLABexec.py';    
funcName = 'Ray_PointCloud2Mesh_ScreenedPoisson.mlx';
% funcName = 'PoissonSample1_LS3Recon1_InvertFaces_script.mlx';

% imgDir = '<redacted original absolute path>';
imgDir = 'Session 45, Exp 3';
imgName = 't%03i_illBleachCorr16bit.tif';

timeRange = 1:20;
chanNums = [2 3];
h5String = '/exported_data';
probThresh = .6;
pixDims = [.37 .37 1.5];      %In um/pixel in [x,y,z]

% Erosion info - "dig" into object to define skeleton
strelRadius = 3;    
strelObj = strel('sphere',abs(strelRadius));

%% Iterate through time, generate .ply objects of point clouds
for tInd = 1:numel(timeRange)    
    % Load data from current time point
    currT = timeRange(tInd);
    currh5Name = fullfile(segDir,sprintf(segName,currT));
    selSegs = sum(loadH5(currh5Name,'/exported_data',[2 3],1),4);
    ogBlobs = imbinarize(sum(selSegs,4),probThresh);
    % To remove erroneous overhangs near blob exteriors, erode then dilate
    erodedBlobs = imerode(ogBlobs,strelObj);
    reconstructedBlobs = imdilate(erodedBlobs,strelObj);
    % Generate skeletonization of blob perimeters
    [skelMat,a,b] = skel3DPop(logical(reconstructedBlobs - erodedBlobs),.5);    

    currImg = double(tiffreadVolume(fullfile(imgDir,sprintf(imgName,currT))));

    % Save skeletonizations as point clouds
    logic2Ply(skelMat, fullfile(ptDir,sprintf(ptName,currT)),scaleMat);
end
fclose all;

%% Convert vertices into mesh - This may not work well; consider splitting objects
scriptLoc = fullfile(meshLabDir, ply2Mesh);
funcLoc = fullfile(meshLabDir, funcName);
pyrunfile(scriptLoc, dataDir = ptDir, saveDir = meshDir, scriptName = funcLoc)

 %% Save blobs as tifs - 10/03/2023
 % blobSaveDir = '<redacted original absolute path>';
 blobSaveDir = 'Session 45, Exp 3';
for tInd = 1:numel(timeRange)
    currT = timeRange(tInd);
    currh5Name = fullfile(segDir,sprintf(segName,currT));
    selSegs = sum(loadH5(currh5Name,'/exported_data',[2 3],1),4);
    ogBlobs = imbinarize(sum(selSegs,4),probThresh);
    % To remove erroneous overhangs near blob exteriors, erode then dilate
    erodedBlobs = imerode(ogBlobs,strelObj);
    reconstructedBlobs = imresize3(imdilate(erodedBlobs,strelObj),round([0.5 0.5 2].*size(erodedBlobs)));

    save3DTiff(uint8(reconstructedBlobs*tInd*10),fullfile(blobSaveDir,sprintf('t%06i.tif',currT)));

end

