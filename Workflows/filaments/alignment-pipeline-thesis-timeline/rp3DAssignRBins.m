%% For all filaments in each rp3D object, get r bin from rDir files
% 2025-04-22 - Rémi Boros
% basestDir = '<redacted original absolute path>';
basestDir = 'Session 88';
subDirs = {'Exp 1', 'Exp 2', 'Exp 3', 'Exp 4 - Rmin Redo', 'Exp 5'};

for index = 1:numel(subDirs)
filDataDir = fullfile(basestDir,subDirs{index},'6 Filament Data\CC Objects');
filDataName = 'Filament Statistics %03i.mat';
rDir = fullfile(basestDir,subDirs{index},'4 Tracked Blobs\In On Out Segmentation');
rName = 'T%03i_CleanInOnOut.tif';
metaDataDir = fullfile(basestDir,subDirs{index},'6 Filament Data');
pause(.1)
ccField = 'rp3D';
fieldStr = 'InOnOutInd';
selTimes = 1:57;

dispBool = 0;

%% Iterate over time
for tInd = 1:numel(selTimes)
% Load Data
    currT = selTimes(tInd);
    if tInd == 1
        load(fullfile(metaDataDir,'metadata.mat'),'imgSize');
    end
    currCCs = load(fullfile(filDataDir,sprintf(filDataName,currT)),ccField).(ccField);
    rMat = double(tiffreadVolume(fullfile(rDir,sprintf(rName,currT))));
    
% Concatenate filament properties
    cenInds = [currCCs.CoMInds(:)];
    scaleInds = rescaleCoords_Inds(cenInds,imgSize,size(rMat));
    % Sample at centers
    fieldAtCens = rMat(scaleInds);
    save(fullfile(filDataDir,sprintf(filDataName,currT)),'fieldAtCens','-append');

    %%% ASIDE TEST %%%
    if dispBool == 1
        uniqueVals = unique(fieldAtCens);
        selLogic = true(size(fieldAtCens));
        centersMat = zeros([imgSize 3]);
        testStrel = strel('sphere',3);
        scMat = imresize3(rMat,imgSize,'nearest');
        for index = 1:3
            currLogic = (fieldAtCens == uniqueVals(index)) & selLogic;
            centersMat(:,:,:,index)  = imdilate(consMatLnB(ones(imgSize),cenInds(currLogic)),testStrel)*150;
            totComs = sum(centersMat,4);
            totBG = consMatLnB(scMat,~logical(totComs));
            finalMat = centersMat + repmat(totBG,1,1,1,3)/3;
            finalMat = uint8(finalMat);
            orthosliceViewer(finalMat);
            pause(1);
        end
    end

end
end

