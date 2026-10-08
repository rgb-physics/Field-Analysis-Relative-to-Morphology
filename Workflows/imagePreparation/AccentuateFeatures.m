% Take in a tif, find smallfeatures by dividing the image convolved with a
% small kernel, then multiply the original image with this "high-bandpass"
% image. This effectively accentutates small wavelength features, good for
% pre-processing before Ilastik
% 2025-04-14 - Rémi Boros

% dataDir = '<redacted original absolute path>';
dataDir = 'Session 87, Exp 2';
dataName = 't%03i_illBleachCorr16bit_560.tif';
% saveDir = '<redacted original absolute path>';
saveDir = 'Session 87, Exp 2';
saveName = dataName;

selTimes = 1:60;
kernSize = 2;

dimScale = [.55 .55 .7]/.7;

%% Iterate over time, load, apply, save
for tInd = 1:numel(selTimes)

    currT = selTimes(tInd);
    currImg = double(tiffreadVolume(fullfile(dataDir,sprintf(dataName,currT))));
    % Resize image, then gauss smooth
    if numel(size(currImg)) == 2
        currImg = imresize(currImg,dimScale.*size(currImg));
        smoothedMat = imgaussfilt(currImg,kernSize);
    elseif numel(size(currImg)) == 3
        currImg = imresize3(currImg,dimScale.*size(currImg));
        smoothedMat = imgaussfilt3(currImg,kernSize);
    end
    % Generate amplified image
    hpMat = currImg./smoothedMat;
    ampedMat = hpMat.*currImg;
    % Save
    save3DTiff(uint16(ampedMat),fullfile(saveDir,sprintf(saveName,currT)));

end