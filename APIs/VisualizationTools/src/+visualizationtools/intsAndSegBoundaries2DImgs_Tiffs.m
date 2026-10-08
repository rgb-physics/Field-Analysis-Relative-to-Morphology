% Load tifs and segmentations/thresholded masks; generate drop boundaries
% and save as stacks 
preName = 'K4_';
% skelDir = '<redacted original absolute path>';
skelDir = 'Session 81, Exp 3';
skelName = 'T%03i_IDedSkelMat.tif';
% blobDir = '<redacted original absolute path>';
blobDir = 'Session 81, Exp 3';
blobName = 'T%03i_trajIDs.tif';
% intDir = '<redacted original absolute path>';
intDir = 'Session 81, Exp 3';
intName = 't%03i_illBleachCorr16bit_488.tif';
% saveDir = '<redacted original absolute path>';
saveDir = 'Session 81, Exp 3';
saveName = [preName 'T%03i_Z%i_Shells_Ints.tif'];

selTimes = 20:2:45;
selZ = 29:31;
midZ = selZ(round(numel(selZ)/2));
mode2D = 2;     % 0 - return 3D tiffs
                % 1 - Sum intensities, sum skels and shells across layers
                % 2 - Sum intensities, mid-z skels and shells only

layerMean = 0;  layerWidth = 1; gKern = 2;
bndVal = 0;   skelVal = -1;         % set less than 0 if you wish to omit either
intBnds = [2000 30000];

%% Iterate over time: load, resize, sub-sample, save
for tInd = 1:numel(selTimes)
    currT = selTimes(tInd);
    % Load data
    loadImg = double(tiffreadVolume(fullfile(intDir,sprintf(intName,currT))));
    if bndVal >= 0
        loadBlob = double(tiffreadVolume(fullfile(blobDir,sprintf(blobName,currT))));
    else
        loadBlob = zeros(size(loadImg));
    end
    if skelVal >= 0
        loadSkel = double(tiffreadVolume(fullfile(skelDir,sprintf(skelName,currT))));
    else
        loadSkel = zeros(size(loadImg));
    end
    % instantiate save directory
    if ~exist(saveDir,'dir')
        mkdir(saveDir);
    end

    % Rescale blobs, get boundaries
    rsBlob = imresize3(loadBlob,size(loadSkel),'nearest');
    smoothBlob = returnSmoothBoundsBW(rsBlob>0,layerMean,layerWidth,gKern);
    % Rescale, sub-sample intensity
    rsBndAll = logical(imresize3(smoothBlob,size(loadImg),'nearest'));
    rsSkelAll = logical(imresize3(loadSkel,size(loadImg),'nearest'));

    % Shift intensities
    delNew = abs(diff(intBnds));
    delOld = 65535;
    scaleFrac = delNew/delOld; 
    shftIntsAll = scaleFrac*(loadImg) + min(intBnds);

    % Select Z range, subsample/average over selected z slices
    if mode2D == 0
        shftInts = shftIntsAll(:,:,selZ);
        rsBnd = rsBndAll(:,:,selZ);     
        rsSkel = rsSkelAll(:,:,selZ);
    elseif mode2D == 1
        shftInts = mean(shftIntsAll(:,:,selZ),3);
        rsBnd = logical(sum(rsBndAll(:,:,selZ),3));     
        rsSkel = logical(sum(rsSkelAll(:,:,selZ),3));
    elseif mode2D == 2
        shftInts = mean(shftIntsAll(:,:,selZ),3);
        rsBnd = rsBndAll(:,:,midZ);     
        rsSkel = rsSkelAll(:,:,midZ);
    end

    % Combine
    baseMat = ones(size(shftInts));
    outImg = consMatLnB(shftInts,~(rsBnd | rsSkel)) + ...
        consMatLnB(baseMat*bndVal,rsBnd) + consMatLnB(baseMat*skelVal,rsSkel);

    % Save
    save3DTiff(uint16(outImg),fullfile(saveDir,sprintf(saveName,currT,midZ)));

end

%% For multiple intensity directories
midZ = 30;  zWidth = 1;
zRange = (midZ-zWidth):(midZ + zWidth);
imgDirs = {intDir,intDir};
imgNames = {'t%03i_illBleachCorr16bit_488.tif','t%03i_illBleachCorr16bit_560.tif'};
zRepos = {zRange, midZ};
sampModes = {2,2};
preNames = {'K4_','MT_'};
saveName = 'T%03i_Z%i_Shells_Ints.tif';
% saveSuper = '<redacted original absolute path>';
saveSuper = 'Session 81, Exp 3';
saveDir = fullfile(saveSuper,sprintf('Z%03i - Only Ints',midZ));
if ~exist(saveDir,'dir')
    mkdir(saveDir)
end

layerMean = 0;  layerWidth = 1; gKern = 2;
bndVal = -1;   skelVal = -1;         % set less than 0 if you wish to omit either
intBnds = [1000 30000];

for tInd = 1:numel(selTimes)
    currT = selTimes(tInd);
    % Load data
    if tInd == 1
        intDir = imgDirs{1};    intName = imgNames{1};
        loadImg = double(tiffreadVolume(fullfile(intDir,sprintf(intName,currT))));
    end
    if bndVal >= 0
        loadBlob = double(tiffreadVolume(fullfile(blobDir,sprintf(blobName,currT))));
    else
        loadBlob = zeros(size(loadImg));
    end
    if skelVal >= 0
        loadSkel = double(tiffreadVolume(fullfile(skelDir,sprintf(skelName,currT))));
    else
        loadSkel = zeros(size(loadImg));
    end
    % instantiate save directory
    if ~exist(saveDir,'dir')
        mkdir(saveDir);
    end

    % Rescale blobs, get boundaries
    rsBlob = imresize3(loadBlob,size(loadSkel),'nearest');
    smoothBlob = returnSmoothBoundsBW(rsBlob>0,layerMean,layerWidth,gKern);
    % Rescale, sub-sample intensity
    rsBndAll = logical(imresize3(smoothBlob,size(loadImg),'nearest'));
    rsSkelAll = logical(imresize3(loadSkel,size(loadImg),'nearest'));

    % Iterate over intensity directories, prepare image data, etc.
    for index = 1:numel(imgDirs)
        % Instantiate modes for current data set
        intDir = imgDirs{index};    intName = imgNames{index};
        preName = preNames{index};
        mode2D = sampModes{index};
        selZ = zRepos{index};
        % midZ =  selZ(round(numel(selZ)/2));
        % Load image
        loadImg = double(tiffreadVolume(fullfile(intDir,sprintf(intName,currT))));
        % Shift intensities
        delNew = abs(diff(intBnds));
        delOld = 65535;
        scaleFrac = delNew/delOld; 
        shftIntsAll = scaleFrac*(loadImg) + min(intBnds);
    
        % Select Z range, subsample/average over selected z slices
        if mode2D == 0
            shftInts = shftIntsAll(:,:,selZ);
            rsBnd = rsBndAll(:,:,selZ);     
            rsSkel = rsSkelAll(:,:,selZ);
        elseif mode2D == 1
            shftInts = mean(shftIntsAll(:,:,selZ),3);
            rsBnd = logical(sum(rsBndAll(:,:,selZ),3));     
            rsSkel = logical(sum(rsSkelAll(:,:,selZ),3));
        elseif mode2D == 2
            shftInts = mean(shftIntsAll(:,:,selZ),3);
            rsBnd = rsBndAll(:,:,midZ);     
            rsSkel = rsSkelAll(:,:,midZ);
        end
    
        % Combine
        baseMat = ones(size(shftInts));
        outImg = consMatLnB(shftInts,~(rsBnd | rsSkel)) + ...
            consMatLnB(baseMat*bndVal,rsBnd) + consMatLnB(baseMat*skelVal,rsSkel);
    
        % Save
        save3DTiff(uint16(outImg),fullfile(saveDir,sprintf([preName saveName],currT,midZ)));
    end

end
