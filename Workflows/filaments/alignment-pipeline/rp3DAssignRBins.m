%% For all filaments in each rp3D object, get r bin from rDir files
% 2025-04-22 - Rémi Boros

% filDataDir = '<redacted original absolute path>';
filDataDir = 'Session 88, Exp 4';
filDataName = 'Filament Statistics %03i.mat';
% rDir = '<redacted original absolute path>';
rDir = 'Session 88, Exp 4';
rName = 'Time%06i_3ChanSegs.tif';

ccField = 'rp3D';
selTimes = 1:70;

dispBool = 0;

%% Iterate over time
for tInd = 1:numel(selTimes)
% Load Data
    currT = selTimes(tInd);
    if tInd == 1
        load(fullfile(filDataDir,'FilamentDetect_metadata.mat'),'imgSize');
    end
    currCCs = load(fullfile(filDataDir,sprintf(filDataName,currT)),ccField).(ccField);
    rMat = double(tiffreadVolume(fullfile(rDir,sprintf(rName,currT))));
    
% Concatenate filament properties
    cenInds = [currCCs.CoMInds(:)];
    scaleInds = rescaleCoords_Inds(cenInds,imgSize,size(rMat));
    % Sample at centers
    rAtCens = rMat(scaleInds);
    save(fullfile(filDataDir,sprintf(filDataName,currT)),'rAtCens','-append');

    %%% ASIDE TEST %%%
    if dispBool == 1
        uniqueVals = unique(rAtCens);
        selLogic = true(size(rAtCens));
        centersMat = zeros([imgSize 3]);
        testStrel = strel('sphere',3);
        scMat = imresize3(rMat,imgSize,'nearest');
        for index = 1:3
            currLogic = (rAtCens == uniqueVals(index)) & selLogic;
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

