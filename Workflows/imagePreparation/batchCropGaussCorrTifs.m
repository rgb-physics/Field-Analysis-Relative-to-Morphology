%% General info
% 09/27/2023
% Directory info

% tifDir = '<redacted original absolute path>';
tifDir = 'Session 87, Exp 2';
tifNameForm = 'Time%06i_raw647.tif';
% saveDir = '<redacted original absolute path>';
saveDir = 'Session 87, Exp 2';
saveNameForm = tifNameForm;
selectTimes = 1:60;

% Range info
metadataBool = 1;
if metadataBool == 1
    % mdDir = '<redacted original absolute path>';
    mdDir = 'Session 87, Exp 2';
    load(fullfile(mdDir,'metadata.mat'));
else
    cropCorner = [1 11 1];
    winSize = [770 793 75];
end

% Gaussian info
gkernel = 40;
gaussDim = 2;       % 2D or 3D gaussian filtering

% Save?
saveBool = 1;
if saveBool == 1
    mkdir(saveDir)
end

%% Iterate through time and crop images (and save)
for tInd = 1:numel(selectTimes)
    currT = selectTimes(tInd);
    currTif = tiffreadVolume(fullfile(tifDir, sprintf(tifNameForm,currT)));
    temp = cropTiffSave(currTif, cropCorner, winSize, 0, '');
    % Correct tif
    if gaussDim == 2
        corrMat = double(imgaussfilt(temp,gkernel));
        tempCorr = double(temp)./corrMat*max(corrMat(:));
    elseif gaussDim == 3
        corrMat = double(imgaussfilt3(temp,gkernel));
        tempCorr = double(temp)./corrMat*max(corrMat(:));
    end
    % Save tif
    if saveBool == 1
        saveName = fullfile(saveDir, sprintf(saveNameForm,currT));
        save3DTiff(uint16(tempCorr),saveName);
    else
        continue
    end
end

if saveBool == 1
    save(fullfile(saveDir, "metadata.mat"), "cropCorner", "winSize", '-mat')
end


