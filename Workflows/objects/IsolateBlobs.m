%% Select a blob at T1 based on coordinates, get ID, then save tifs of IDs over time
% Segmented images are expected to be tifs with trajectory IDs stored at
% object indices. For trajectory-independent/overlap only tracking, use
% IsolateBlobLineage.m. To generate tifs of bwlabeln trajectory blobs, use 
% overlapBlobTracking.m
% Rémi Boros
% 2024-09-18

% Parameters
% baseDir = 'Session 85';
% segDir = '<redacted original absolute path>';
segDir = 'Session 84';
segNameForm = 'T%03i_filtIDs.tif';
% saveBaseDir = '<redacted original absolute path>';
saveBaseDir = 'Session 84';
saveNameForm = '%s%st%03i_SplitTrajs.tif';

selTimes = 1:50;
pixConv = [1 1 1];
% pixConv = [.37 .37 .5];
t1Coords = round([110 110 35]);     % 3x(num coords)
dispOtherObjs = 0;
dispValue = 50;
lineageBool = 0;
lineageStep = 200;

saveBool = 1;

%% Iterate and search over time
% if ~exist(saveDir,'dir')
%     mkdir(saveDir);
% end

for tInd = 1:numel(selTimes)
    % Load data
    currT = selTimes(tInd);
    labeledMat = double(tiffreadVolume(fullfile(segDir,sprintf(segNameForm,currT))));

    % Get blob overlapping with logic or matrix index (row,col,dep)
    if tInd == 1
        lineageVals = [];
        matrixInds = sub2ind(size(labeledMat),t1Coords(:,2),t1Coords(:,1),t1Coords(:,3));
        % Get bwlabeln labels of objects overlapping with logicMat
        labelVals = unique(labeledMat(matrixInds));
        saveDir = fullfile(saveBaseDir,sprintf('Traj %i',labelVals(1)));
        if (saveBool == 1) && ~exist(saveDir,'dir')
            mkdir(saveDir);
        end
    else
        if lineageBool == 1
             lineageVals = unique(labeledMat(matrixInds));
             lineageVals = lineageVals(~ismember(lineageVals,[0 labelVals']));
        end
    end

    % Subsample labeled matrix for all pixels with labelVals
    subSampleMat = consMatLnB(labeledMat,ismember(labeledMat,labelVals));

    % Include other objects, if requested, and sub sample desired trajs
    if dispOtherObjs == 1
        baseMat = logical(labeledMat)*dispValue;
        subSampleMat = max(0,subSampleMat-dispValue);
        otherString = 'other_';
    else
        if tInd == 1
            baseMat = zeros(size(labeledMat));
            otherString = '';
        end
    end 
    % Define matrix for lineage
    if lineageBool == 1
        lineageMat = ismember(labeledMat,lineageVals)*(lineageStep - dispValue);
        lineageString = 'lineage_';
    else
        if tInd == 1
            lineageMat = zeros(size(labeledMat));
            lineageString = '';
        end
    end

    saveMat = baseMat + subSampleMat + lineageMat;
        
    % Save, if requested
    if saveBool == 1
        save3DTiff(uint16(saveMat),fullfile(saveDir,sprintf(saveNameForm,otherString,lineageString,currT)));
    end

    % Add to label values if tracking lineage
    if lineageBool == 1
        matrixInds = find(subSampleMat + lineageMat);
    end

end

%% Additional %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%








