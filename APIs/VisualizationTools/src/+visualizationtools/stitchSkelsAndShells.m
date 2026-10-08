%% Combine blob skeletons with blob surface contours, then save in tiffs
% Takes in 3D .tifs of blob skeletons and of ID-ed blobs. Skeletons are
% assigned static value or match blob ID. Dimensions are matched to ID-ed
% blobs where voxels are assumed to be cubical
% Rémi Boros - 2026/04/28

% blobDirs = {'<redacted original absolute path>',...
blobDirs = {'Session 88, Exp 1',...
    % '<redacted original absolute path>',...
    'Session 88, Exp 2',...
    % '<redacted original absolute path>',...
    'Session 88, Exp 3',...
    % '<redacted original absolute path>',...
    'Session 88, Exp 4',...
    % '<redacted original absolute path>'};
    'Session 88, Exp 5'};

for index = 1:numel(blobDirs)
% Directory info
blobDir = blobDirs{index};
blobName = 'E%i_T%03i_trajIDs.tif';
skelDir = fullfile(blobDir,'RMinStats');
skelName = 'T%03i_IDedSkelMat.tif';
saveDir = fullfile(blobDir,'Shells and Skels');
saveName = 'E%i_T%03i_ShellSkel.tif';

selTimes = 1:50;
rsFact = 1.5;
shellMid = 0;
shellWidth = .75;

if ~exist(saveDir,'dir')
    mkdir(saveDir);
end

%% Iterate over time

for tInd = 1:numel(selTimes)
    currT = selTimes(tInd);
    % Load data
    currBlobs = tiffreadVolume(fullfile(blobDir,sprintf(blobName,index,currT)));
    currSkels = tiffreadVolume(fullfile(skelDir,sprintf(skelName,currT)));
    % Define output dimensions
    if tInd == 1
        outSize = size(currBlobs)*rsFact;
        shellWidth = shellWidth*rsFact;
    end
    % Rescale matrices
    rsBlobs = imresize3(currBlobs,outSize,'nearest');
    rsSkels = imresize3(currSkels,outSize,'nearest');
    % Generate shells
    blobShells = returnSmoothBoundsIDed(rsBlobs,shellMid,shellWidth,2,'fast');

    % Combine shells and skeletons
    combMat = blobShells; 
    combMat(logical(rsSkels)) = 1000;    
    % combMat(logical(rsSkels)) = rsSkels(rsSkels>0);    

    % Save image
    save3DTiff(uint16(combMat),fullfile(saveDir,sprintf(saveName,index,currT)));

end

end
