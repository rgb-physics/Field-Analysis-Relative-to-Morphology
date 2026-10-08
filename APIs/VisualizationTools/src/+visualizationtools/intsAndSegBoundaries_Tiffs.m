% Load tifs and segmentations/thresholded masks; generate drop boundaries
% and save as stacks 
preName = 'MTs_';
% intsDir = '<redacted original absolute path>';
intsDir = 'Session 81, Exp 3';
intsName = 't%03i_illBleachCorr16bit_488.tif';
% segsDir = '<redacted original absolute path>';
segsDir = 'Session 81, Exp 3';
segsName = 'T%03i_trajIDs.tif';
% saveDir = '<redacted original absolute path>';
saveDir = 'Session 81, Exp 3';
saveName = 'vesicleBounds_T%03i_K4.tif';

selTimes = 1:125;
strelRad = -1;
boundValue = 255;
segThresh = 1;
bwScale = 2;
postSmooth = 1;
% Comment out if you want to match to size of original tif
% outDims = [785 770 69];

if ~exist(saveDir,'dir')
    mkdir(saveDir);
end

%% Iterate through time, load, dilate, carve, save

strelObj = strel('sphere',abs(strelRad));
for tInd = 1:numel(selTimes)

    currT = selTimes(tInd);
    currInts = double(tiffreadVolume(fullfile(intsDir,sprintf(intsName,currT))));
    currSegs = tiffreadVolume(fullfile(segsDir,sprintf(segsName,currT)));
    % Smooth, then resize to cubic
    currSegs = imresize3(imgaussfilt3(currSegs,2),size(currSegs)*bwScale);

    if tInd == 1
        intsSize = size(currInts);
        segsSize = size(currSegs);
        roughScale = max(intsSize./segsSize);
        bndKern = round(roughScale);
    end
    
    % currBW = logical(currSegs);
    currBW = currSegs >= segThresh;
    if strelRad > 0
        secondMask = imdilate(currBW,strelObj);
        boundaryMat = secondMask - currBW;
    else
        secondMask = imerode(currBW,strelObj);
        boundaryMat = currBW - secondMask;
    end

    % Smooth
    % scaledBnd = imresize3(boundaryMat,bndKern*segsSize);
    % smoothBnd = imgaussfilt3(scaledBnd,bndKern);
    % erodedBnd = imerode(imbinarize(smoothBnd,.5),strel('sphere',1));
    % Rescale
    % if exist('outDims','var')
    %     % bndLogic = imresize3(erodedBnd,outDims,'nearest');
    %     bndLogic = logical(imresize3(erodedBnd,outDims));
    %     currInts = imresize3(currInts,outDims,'nearest');
    % else
    %     bndLogic = imresize3(erodedBnd,intsSize,'nearest');
    % end
    if postSmooth > 0
        secStrel = strel('sphere',postSmooth);
        boundaryMat = imerode(imdilate(boundaryMat,secStrel),secStrel);
    end
    bndLogic = logical(imresize3(boundaryMat,size(currInts),'nearest'));
    saveMat = consMatLnB(currInts,~logical(bndLogic)) + boundValue*bndLogic;
    % saveMat = consMatLnB(currInts,~logical(boundaryMat)) + boundValue*boundaryMat;
    save3DTiff(uint8(saveMat*(255/65535)),fullfile(saveDir,sprintf(saveName,currT)));
    % save3DTiff(uint16(saveMat),fullfile(saveDir,sprintf(saveName,currT)));

end

%% Split Tifs, if needed
% mtName = ['MTs_' intsName]; kifName = ['Kif_' intsName];
% for tInd = 1:numel(selTimes)
%     currT = selTimes(tInd);
%     currInts = tiffreadVolume(fullfile(intsDir,sprintf(intsName,currT)));
%     mtInts = currInts(:,:,1:2:end);
%     kifInts = currInts(:,:,2:2:end);
%     save3DTiff(mtInts,fullfile(intsDir,sprintf(mtName,currT)));
%     save3DTiff(kifInts,fullfile(intsDir,sprintf(kifName,currT)));
% 
% end

%% OLD
    % currBW = min(1,max(0,imresize3(double(logical(currSegs)),roughScale*segsSize)));
    % test = imdilate(imerode((currBW),strel('sphere',2)),strel('sphere',2));
    % currBW = imresize3(logical(currSegs),roughScale*segsSize,'nearest');
    % Smooth
    % distMat = double(bwdist(boundaryMat));
    % test = imresize3(distMat,segsSize*roughScale);
    % test2 = imgaussfilt3(test,bndKern);
    % blurDist = imgaussfilt3(distMat,bndKern);
    % [~,~,indMat] = histcounts(blurDist,[-Inf -strelRad strelRad Inf]);
    % % [~,~,indMat] = histcounts(distMat,[-Inf -bndKern/3 bndKern/3 Inf]);
    % bndLogic = indMat < max(indMat(:));
    % blurSubSamp = consMatLnB(blurDist,bndLogic);
    % ringScaleMat = min(blurDist,max(blurSubSamp(bndLogic)))/max(indMat(:));
    % 
    % test = imresize3(bndLogic,intsSize,'nearest');
    % outMat = currInts.*imresize3(ringScaleMat,intsSize,'nearest');
    % boundaryMat = imresize3(boundaryMat,size(currInts),'nearest');