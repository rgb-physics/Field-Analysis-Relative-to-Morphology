%% Outline and testing to isolate blobs spatially and temporally
% Rémi Boros
% 2024-05-13 

% Parameters
% baseDir = 'Session 85';
% segDir = '<redacted original absolute path>';
segDir = 'Session 84';
segNameForm = 'BlobMat_t%03i_illBleachCorr16bit.tif';

selTimes = 5:25;
binBool = 1;            % if 1, bin input and relabel with bwlabeln
binNum = 2;
blobBins = 2;
% pixConv = round([580 581 81]./[218 219 41]);
pixConv = [1 1 1];
t1Coords = round([420 207  51].*pixConv);     % 3x(num coords)

% Remove objects touching perimeters?
borderBool = 0;
borderPerim = 2;

saveBool = 1;
% saveDir = '<redacted original absolute path>';
saveDir = 'Session 84';
saveNameForm = 't%03i_trajectory_lineage.tif';

%% Iterate and search over time
if ~exist(saveDir,'dir')
    mkdir(saveDir);
end

for tInd = 1:numel(selTimes)
    % Load data
    currT = selTimes(tInd);
    currSeg = tiffreadVolume(fullfile(segDir,sprintf(segNameForm,currT)));
    
    % Prep data
    if binBool == 1
        [~,~,indMat] = histcounts(double(currSeg),binNum);
        logicMat = ismember(indMat,blobBins);
        labeledMat = bwlabeln(logicMat);
    else
        labeledMat = currSeg;
    end

% Choose isolation mode
    % Remove objects around boundaries
    if borderBool == 1
        if tInd == 1
            logicMat  = ~padarray(ones(size(currSeg)-2*borderPerim),[1 1 1]*borderPerim);
            matrixInds = find(logicMat);
        end
    % Get blob overlapping with logic or matrix index (row,col,dep)
    else
        if tInd == 1
            matrixInds = sub2ind(size(labeledMat),t1Coords(:,2),t1Coords(:,1),t1Coords(:,3));
            if (saveBool == 1) && ~exist(saveDir,'dir')
                mkdir(saveDir);
            end
        else
            matrixInds = find(subSampleLogic);
        end
    end

    % Get bwlabeln labels of objects overlapping with logicMat
    labelVals = unique(labeledMat(matrixInds));
    % Remove objects touching border
    if borderBool == 1
        subSampleLogic = ~ismember(labeledMat,labelVals);
    % Keep only selected blobs
    else
        labelVals = labelVals(labelVals > 0);
        subSampleLogic = ismember(labeledMat,labelVals);
    end

    % Save, if requested
    if saveBool == 1
        save3DTiff(uint8(subSampleLogic),fullfile(saveDir,sprintf(saveNameForm,currT)));
    end

end


%% Additional %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%








