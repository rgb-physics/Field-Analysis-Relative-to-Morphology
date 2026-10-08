%% Takes in .h5 segmentation and int corrected .tif, returns perimeters
% Saves .tifs of segmentation perimeters for easy visualization
% 2023/11/02
% h5Dir = '<redacted original absolute path>';
h5Dir = 'Session 81, Exp 3';
h5Name = 't%03i_illCorr8bit_560_Probabilities Stage 2.h5';
% imgDir= '<redacted original absolute path>';
imgDir= 'Session 81, Exp 3';
imgName = 't%03i_illBleachCorr16bit_560.tif';
% saveDir = '<redacted original absolute path>';
saveDir = 'Session 45, Exp 3';
saveName = 'inOnPerim_t%03i.tif';

threshVal = 0.33;
timeRange = 1:100;
objChans = [1 2 3];
% in terms of number of channels above
outInOn = [1 2 3];
strelRad = 2;   strelObj = strel('sphere',strelRad);
scaleVec = [1 1 4]/2;


%% Iterate through time, get intensity and bin info around drop perimeters
for tInd = 1:numel(timeRange)

    % Load current frame info
    currT = timeRange(tInd);    
    if mod(tInd,10) == 1
        fprintf('Currently analyzing frame %i...\n',currT);
    end
    % For session 45 exp 3
    if tInd > 49
        objChans = [3 1 2];
    end
    currSeg = loadH5(fullfile(h5Dir,sprintf(h5Name,currT)),'/exported_data',objChans);
    currImg = tiffreadVolume(fullfile(imgDir,sprintf(imgName,currT)));
    scaledImg = imresize3(currImg,round(size(currImg).*scaleVec));
    
    % Define smoothed regions, then get boundaries and distance transforms
    [cleanIns,cleanOuts,cleanOns] = h5toSmooth3Chans(...
        imresize3_4mat(currSeg,size(scaledImg)),outInOn,threshVal,strelRad,1);
    [distMat,globalDistMat,regionFlip,primbgInds,secbgInds,layLogicMat] = ...
        distTransFromBoundary(cleanOns, cleanOuts, cleanIns, strelRad);
    
    save3DTiff(uint8(255*(secbgInds + primbgInds)),fullfile(saveDir,sprintf(saveName,currT)));

end
