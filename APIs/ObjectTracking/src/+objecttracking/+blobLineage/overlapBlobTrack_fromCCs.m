% Assumes blobs are segmented and saved as connected component objects for
% each time point. The method compares overlapping indices between
% consecutive time points, samples object IDs at said indices, looks for
% unique ID pairs between time frames, then assigns trajectory IDs.
% Rémi Boros, 2024-08-16

% dataDir = '<redacted original absolute path>';
dataDir = 'Session 84';
dataName = 'objIDs_T%06i.mat';
% saveDir = '<redacted original absolute path>';
saveDir = 'Session 84';
saveName = 'BlobMat_t%03i_inheritedLabels_cc.tif';

selectTimes = 1:100;
% resetNewID = 0;

saveBool = 1;
newObjsBool = 1;            % Generate trajectories for nucleating objects
truncateMergers = 0;        % End trajectories when drops merge (new traj for child)
truncateSplitters = 0;      % End trajectories when drops split (new trajs for each child)
maskBool = 1;
maskTime = 1;

%% Make directory
if ~exist(saveDir,'dir')
    mkdir(saveDir);
end

%% Iterate over time
for tInd = 1:(numel(selectTimes) - 1)

    if tInd == 1
        load(fullfile(dataDir,sprintf(dataName,selectTimes(1))));
        [~, objVoxels1, objIDs1] = getCCVectors(currCC);
    end

    % Load data sets
    nextT = selectTimes(tInd+1);
    load(fullfile(dataDir,sprintf(dataName,nextT)));
    [~, objVoxels2, objIDs2] = getCCVectors(currCC);

    % Prepare data labels and logical matrices
    if tInd == 1
        nextID = max(objIDs1(:)) + 1;
    end 
    
    % Get overlapping indices between frames
    overlapInds1 = ismember(objVoxels1,objVoxels2);
    overlapInds2 = ismember(objVoxels2,objVoxels1);
    % Get object labels at overlapping inds over consecutive time points
    % objectIndexPairs = [objVoxels2(overlapInds2),objVoxels1(overlapInds1)];
    objectLabelPairs = [objIDs2(overlapInds2),objIDs1(overlapInds1)];
    uniqueObjectPairs = unique(objectLabelPairs,"rows");
   
    % Generate new trajectory inheritance for merger events
    if truncateMergers == 1
        [labelCounts,labelIDs] = groupcounts(uniqueObjectPairs(:,1));
        mergerLabels = labelIDs(labelCounts>1);
        mergerInds = ismember(uniqueObjectPairs(:,1),mergerLabels);
        for currLabel = 1:numel(mergerLabels)
            currInds = uniqueObjectPairs(:,1) == mergerLabels(currLabel);
            uniqueObjectPairs(currInds,2) = nextID;
            nextID = nextID + 1;
        end
    end

    % Remove degenerate cases from object merging
        % Object pairs are ordered wrt objects in frame 2; Remove ordered pairs
        % in cases where there are repetitions of objects in frame 2
    degenerateCases = logical([0; diff(uniqueObjectPairs(:,1)) == 0]);
    if isempty(uniqueObjectPairs)   
        keptPairs = uniqueObjectPairs;
    else
        keptPairs = uniqueObjectPairs(~degenerateCases,:);
    end

    %% Generate a mapping vector for inheritance - need to generate matrtices
    labeledObjs2 = zeros(currCC.ImageSize); labeledObjs1 = labeledObjs2;
    labeledObjs2(objVoxels2) = objIDs2; labeledObjs1(objVoxels1) = objIDs1;
    mapVector = zeros(numel(unique(labeledObjs2)) - ismember(0,labeledObjs2),1);
        % Assign indices corresponding to frame two labels with non-degenerate
        % object labels from frame 1
    mapVector(keptPairs(:,1)) = keptPairs(:,2);

    if newObjsBool == 1
        % Find nucleated/new objects in new time point
            % Compare labels at indices in frame 2 that overlap with zeros in frame 
            % 1 to the list of all unique labels in frame 2. Any new labels must be
            % accounted for and added
        labelsOfNewInds = unique(labeledObjs2(~frameOneLogical));
        uniqueNewLabels = labelsOfNewInds(~ismember(labelsOfNewInds,keptPairs(:,1)));
            % Remove 0
        uniqueNewLabels = uniqueNewLabels(2:end);
            % Assign indices to new objects
        mapVector(uniqueNewLabels) = (1:numel(uniqueNewLabels)) + nextID;
        nextID = nextID + numel(uniqueNewLabels);
        % mapVector(uniqueNewLabels) = (1:numel(uniqueNewLabels)) + size(keptPairs,1);
    end

    % Assign inheritance to trajectories
        % Duplicate frame 2, then get vector of labels > 0
    inheritMat = labeledObjs2;
    nonzeroLabels = inheritMat(frameTwoLogical);
        % Map using map vector, then indices in duplicated inheritance matrix
    inheritMat(frameTwoLogical) = mapVector(nonzeroLabels);
    
    % Save, if requested
    if saveBool == 1
        if tInd == 1
            currT = selectTimes(tInd);
            save3DTiff(uint16(objIDs1),fullfile(saveDir,sprintf(saveName,currT)));
        end
        save3DTiff(uint16(inheritMat),fullfile(saveDir,sprintf(saveName,nextT)));
    end

    % Assign frame two info to frame 1
    frameOneLogical = frameTwoLogical;
    objIDs1 = inheritMat;
    objVoxels1 = find(frameOneLogical); 

end



