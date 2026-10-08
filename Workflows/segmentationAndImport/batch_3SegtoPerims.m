%% Get segmentation perimeters from 3 class segmentations
% Segmentations should be stored in .tif form. Calculates the distance
% transform at a boundary and saves new tif
% Rémi Boros 2024-03-29

%% Parameters
% dataDir = '<redacted original absolute path>';
dataDir = 'Session 56, Exp 2';
dataNameForm = 't%03i_illBleachCorr16bit.tif';
% saveDir = '<redacted original absolute path>';
saveDir = 'Session 56, Exp 2';
saveName = 't%03i_perimeters_%s.tif';
tifTag = '560MTs';

timeRange = 1:40;
numChans = 3;
outChan = 1;    inChan = 3;     onChan = 2;
primChan = onChan;  bgChan = outChan;  secChan = inChan;
ringCenter = 0;
ringWidth = 3;
perimInvertBool = 1;
uint8Incr = 85;

subSampleBool = 1;
% subSampleDir = '<redacted original absolute path>';
subSampleDir = 'Session 56, Exp 2';
subSampleName = 't%03i_illBleachCorr16bit.tif';
saveTif = 1;
savePerims = 1;

%% Iterate over time
if ~exist(saveDir,'dir')
    mkdir(saveDir);
end
% Define io bounds, oo bounds, and tif w/o bounds
if ~exist(fullfile(saveDir,'Out-On Perim'),'dir')
    mkdir(fullfile(saveDir,'Out-On Perim'));
    mkdir(fullfile(saveDir,'In-On Perim'));
    mkdir(fullfile(saveDir,'Tifs without Perims'));
end

for tInd = 1:numel(timeRange)
    % Load current time info
    currT = timeRange(tInd);
    currTif = tiffreadVolume(fullfile(subSampleDir,sprintf(subSampleName,currT)));
    currSegs = tiffreadVolume(fullfile(dataDir,sprintf(dataNameForm,currT)));
    % Remove uint8 smoothing artifacts
    currSegs = round(currSegs/uint8Incr);
    [~,~,currSegsScaled] = histcounts(imresize3(currSegs,size(currTif)),3);

    % Manually remove small cusps of "on" w/ distance transform
    distIns = bwdist(currSegsScaled == inChan);
    distOuts = bwdist(currSegsScaled == outChan);
    [insDX,insDY,insDZ] = gradient(distIns);
    [outsDX,outsDY,outsDZ] = gradient(distOuts);
    % Isolate voxels "between" inside and outside
    crossoverMat = (insDX.*outsDX < 0) | (insDY.*outsDY < 0) | (insDZ.*outsDZ < 0);
    % Isolate voxels close to inside and outside segmentations only
    cutoffBin = 1;
    [~,~,cutoffIns] = histcounts(distIns,[0 cutoffBin 2*cutoffBin]);
    [~,~,cutoffOuts] = histcounts(distOuts,[0 cutoffBin 2*cutoffBin]);
    fullLogicMask = cutoffIns & cutoffOuts & crossoverMat;
    % Manually flip "on" segs in mask region to "in" segs
    newCurrSegs = consMatLnB(currSegsScaled,~fullLogicMask) ...
        + consMatLnB(inChan*ones(size(currSegsScaled)),fullLogicMask);
    % Distance and level set 0 info for outside-on boundary
    [distMatOO,~,~,~,~,primProximalIndsOO] = distTransFromBoundary(newCurrSegs==onChan, ...
        newCurrSegs==outChan, newCurrSegs==inChan, 1);
    all0sOO = (distMatOO < 1) & (distMatOO > -1);
    zeroSetOO = consMatLnB(all0sOO,primProximalIndsOO);
    % Distance and level set 0 info for on-inside boundary
    [distMatIO,~,~,~,~,primProximalIndsIO] = distTransFromBoundary(newCurrSegs==inChan, ...
        newCurrSegs==onChan, newCurrSegs==outChan, 1);
    all0sIO = (distMatIO < 1) & (distMatIO > -1);
    zeroSetIO = consMatLnB(all0sIO,primProximalIndsIO);
    
    % Save, if requested
    if saveTif == 1
        tifWO = consMatLnB(currTif,~(zeroSetIO|zeroSetOO));
        save3DTiff(tifWO,fullfile(saveDir,'Tifs without Perims',sprintf(saveName,currT,tifTag)));
    end
    if savePerims == 1
        save3DTiff(uint16(zeroSetIO*255),fullfile(saveDir,'In-On Perim',sprintf(saveName,currT,'io')));
        save3DTiff(uint16(zeroSetOO*255),fullfile(saveDir,'Out-On Perim',sprintf(saveName,currT,'oo')));
        save(fullfile(saveDir,sprintf('PerimInfo_t%03i.mat',currT)),'zeroSetOO','zeroSetIO');
    end
end

%% Load perimeter(s) from .mat files and sub-sample tifs
selPerim = {'zeroSetOO'};
% tifDir = '<redacted original absolute path>';
tifDir = 'Session 56, Exp 2';
tifTag = sprintf('488MTs_%s',[selPerim{:}]);
tifName = 't%03i_illBleachCorr16bit_488.tif';
% perimDir = '<redacted original absolute path>';
perimDir = 'Session 56, Exp 2';
perimName = 'PerimInfo_t%03i.mat';
% saveDir = '<redacted original absolute path>';
saveDir = 'Session 56, Exp 2';
saveSubDir = 'Tifs Without Perimeters';
saveName = '%s_t%03i_perimeters%i.tif';

timeRange = 1:40;
perimCap = 0;

% Iterate over time
for tInd = 1:numel(timeRange)
    currT = timeRange(tInd);
    currTif = tiffreadVolume(fullfile(tifDir,sprintf(tifName,currT)));
    % Instantiate dummy perimeter matrices
    if tInd == 1
        imgSize = size(currTif);
        zeroSetOO = zeros(imgSize);   zeroSetIO = zeroSetOO;
        if ~exist(fullfile(saveDir,saveSubDir),'dir')
            mkdir(fullfile(saveDir,saveSubDir));
        end
    end
    % Load perimeter data and generate mask
    load(fullfile(perimDir,sprintf(perimName,currT)),selPerim{:});
    perimLogic = ~(zeroSetIO|zeroSetOO);
    % Sub-sample tif using mask and save
    subSamp = consMatLnB(currTif,perimLogic) + uint16(consMatLnB(perimCap*ones(imgSize),~perimLogic));
    save3DTiff(subSamp,fullfile(saveDir,saveSubDir,sprintf(saveName,tifTag,currT,perimCap)));
end



