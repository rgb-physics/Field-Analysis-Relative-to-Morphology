% Takes in directory of blob objects saved tif per time point. Checks for
% overlaps in object indices between consecutive time points, samples
% object labels of each, then samples unique pairs of labels between the
% two time points. Optionally reconstructs tifs with blobs labeled per
% object ancestry/inherited blob index 
% This script assumes minimal object drift; object overlap between frames
% is assumed enough for inheritence
% Rémi Boros, 2024-06-17; 2024-10-17

% The goal: store object IDs using a directed graph. 

% dataDir = '<redacted original absolute path>';
dataDir = '';
dataName = '2D_T%06i_clusterIDs.tif';
% saveDir = '<redacted original absolute path>';
saveDir = '';
saveName = 'T%06i_FLAT_TRACKED_clusterIDs.tif';

selectTimes = 1:265;
% selectTimes = 215:-1:190;
% resetNewID = 0;

saveBool = 1;
newObjsBool = 1;            % Generate trajectories for nucleating objects 
truncateMergers = 1;        % End trajectories when drops merge (new traj for child) - otherwise, inheritance goes to largest boject
truncateSplitters = 0;      % End trajectories when drops split (new trajs for each child)
maskBool = 0;

labeledInput = 1;           % If zero, binarize, then bwlabeln to get IDs

uniqueFrame1 = 0;
% dataDir1 = '<redacted original absolute path>';
dataDir1 = '';
dataName1 = 'eroded_T215.tif';

ccFields = {'Centroid','Area','PixelIdxList','MajorAxisLength','MinorAxisLength'};
% ccFields = {'Centroid','Volume','VoxelIdxList','PrincipalAxisLength'};

%% Make directory
if ~exist(saveDir,'dir')
    mkdir(saveDir);
end
if ~exist(fullfile(saveDir,'Masked Blobs'),'dir')
    mkdir(fullfile(saveDir,'Masked Blobs'));
    mkdir(fullfile(saveDir,'Masked CCs'));
end

%% Iterate over time
ogPairs = [];
allNucleatedPairs = [];
% Generate cells of centroids and areas at T_ref; link to object IDs at T1
for tInd = 1:(numel(selectTimes) - 1)

    % Load data sets
    nextT = selectTimes(tInd+1);
    frameTwo = double(tiffreadVolume(fullfile(dataDir,sprintf(dataName,nextT))));

% Prepare data labels and logical matrices
    % Prepare frame one data
    if tInd == 1
        if uniqueFrame1 == 1
            labeledObjs1 = double(tiffreadVolume(fullfile(dataDir1,dataName1)));
        else
            previousT = selectTimes(1);
            frameOne = double(tiffreadVolume(fullfile(dataDir,sprintf(dataName,previousT))));
            if labeledInput == 1
                labeledObjs1 = frameOne;
            else
                labeledObjs1 = bwlabeln(frameOneLogical);
            end
            frameOneLogical = logical(labeledObjs1);
        end
        indVec1 = find(frameOneLogical); 
        nextID = max(labeledObjs1(:)) + 1;
    end
    [objVols1, objIDs1] = groupcounts(labeledObjs1(labeledObjs1>0));
    
    % Prepare frame two data
    if labeledInput == 1
        labeledObjs2 = frameTwo;
    else
        labeledObjs2 = bwlabeln(frameTwoLogical);
    end
    frameTwoLogical = logical(frameTwo);
    indVec2 = find(frameTwoLogical);   
    [objVols2, objIDs2] = groupcounts(labeledObjs2(labeledObjs2>0));

% First pass of object lineage
    % Get overlapping indices between frames
    overlapInds = indVec1(ismember(indVec1,indVec2));
    % Get object labels at overlapping inds over consecutive time points
    objectLabelPairs = [labeledObjs1(overlapInds),labeledObjs2(overlapInds)];
    uniqueObjectPairs = unique(objectLabelPairs,"rows");
    pairsAndTimes = uniqueObjectPairs; 
    pairsAndTimes(:,3) = previousT; pairsAndTimes(:,4) = nextT;
    ogPairs = [ogPairs; pairsAndTimes];         % [Source IDs, Target IDs, T_i, T_i+1]

% Append nucleated objects
nucleatedIDs = objIDs2(~ismember(objIDs2,uniqueObjectPairs(:,2)));
if ~isempty(nucleatedIDs)
    nucPairs = zeros(numel(nucleatedIDs),4);
    nucPairs(:,2) = nucleatedIDs;
    nucPairs(:,3) = previousT;    nucPairs(:,4) = nextT;
    allNucleatedPairs = [allNucleatedPairs; nucPairs];
end

% Clean up for next time
    frameOneLogical = frameTwoLogical;
    labeledObjs1 = labeledObjs2;
    indVec1 = find(frameOneLogical); 
    previousT = nextT;

end

%% Get indices of all merge and split events    (Need nucleating objects, too)
% Find merging and splitting events by checking for repetitions
mergeCheck = (diff(ogPairs(:,2)) == 0);
splitCheck = (diff(ogPairs(:,1)) == 0);
% Get row indices corresponding to merging and splitting IDs
mergeLogic = ismember(ogPairs(:,[2 3]),ogPairs(mergeCheck,[2 3]),'rows');
splitLogic = ismember(ogPairs(:,[1 3]),ogPairs(splitCheck,[1 3]),'rows');
% Get number of unique merge and split events
mergeRows = ogPairs(mergeLogic,[3 1]);          % [Time1, source IDs]
splitRows = ogPairs(splitLogic,[3 1]);
[~,~,mergeRowInds] = unique(mergeRows,'rows');
[~,~,splitRowInds] = unique(splitRows,'rows');
mergeCount = numel(unique(mergeRowInds));
splitCount = numel(unique(splitRowInds));

% Use largest default object ID as starter "carry over" ID
nextID = max(max(ogPairs(:,1:2))) + 1;
% Get vectors of new IDs to assign for merge and split events
replaceMergers = nextID + (1:mergeCount);
replaceSplits = nextID + mergeCount + (1:splitCount);

% Update targets using "carry over" indices
updatedPairs = ogPairs;
updatedPairs(mergeLogic,2) = replaceMergers(mergeRowInds);
updatedPairs(splitLogic,2) = replaceSplits(splitRowInds);

%% Update sources using targets from previous frame
startInd = 100;
previousT = selectTimes(startInd);
% previousT = selectTimes(1);
tLogic = updatedPairs(:,4) == previousT;
previousTargets_raw = ogPairs(tLogic,2);
previousTargets = updatedPairs(tLogic,2);
for tInd = (startInd+1):numel(selectTimes)
    % Get current time and collection of associated node tuples
    nextT = selectTimes(tInd);
    tLogic = updatedPairs(:,4) == nextT;
    currSources = updatedPairs(tLogic,1);
    currTarget = updatedPairs(tLogic,2);
    % Update logic for time and merge/split
    mergeInds = mergeLogic & tLogic;
    splitInds = splitLogic & tLogic;
    % Update mergers
    % updatedPairs(mergeInds) = 
    if sum(splitInds) > 0
        ogPairs(splitInds,:)
    end
    find(splitInds)

end

%%

% Append nucleated objects
updatedPairs = [updatedPairs; allNucleatedPairs];


%% 

% Assign IDs to merged objects; T_i objects are parents, T_i+1 is the child 
    % Generate new trajectory inheritance for merger events
    [labelCountsM,labelIDsM] = groupcounts(currTarget);             % Identify repeats in target IDs
    mergerLabels = labelIDsM(labelCountsM>1);                       % Get list of repeated target IDs
    % Iterate through each repeated label and assign appropriate IDs
    for labelInd = 1:numel(mergerLabels)
        currLabel = mergerLabels(labelInd);
        labelIndices = find(uniqueObjectPairs(:,1) == currLabel);
        % If truncating trajectories upon merger event
        if truncateMergers == 1
            updateIDs = nextID;
            nextID = nextID + 1;
        % If continuing trajectories through mergers, keep ID of larger parent
        else
            mergerParentIDs = uniqueObjectPairs(labelIndices,2);
            volsOfParents = objVols1(ismember(objIDs1,mergerParentIDs));      % Fewer numbers of objects than max ID as time progresses -> get indices of appropriate objects
            [~, largestVolInd] = max(volsOfParents);
            updateIDs = mergerParentIDs(largestVolInd);
        end
        uniqueObjectPairs(labelIndices,2) = updateIDs;
        
        % (labelIndices) = updateIDs;
    end

    pairsAndTimes = uniqueObjectPairs; pairsAndTimes(:,3) = nextT;
    mergedPairsALL = [mergedPairsALL; pairsAndTimes];

    
    % Remove degenerate cases from object merging
        % Object pairs are ordered wrt objects in frame 2; Remove ordered pairs
        % in cases where there are repetitions of objects in frame 2
    degenerateCases = logical([0; diff(uniqueObjectPairs(:,1)) == 0]);
    if isempty(uniqueObjectPairs)   
        keptPairs = uniqueObjectPairs;
    else
        keptPairs = uniqueObjectPairs(~degenerateCases,:);
    end

    pairsAndTimes = keptPairs; pairsAndTimes(:,3) = nextT;
    mergedPairsUnique = [mergedPairsUnique; pairsAndTimes];


% end
%% 

% Assign IDs to truncated objects; T_i is single parent, T_i+1 are children
% (flipped case of mergers)
    % Generate new trajectory inheritance for merger events
    [labelCountsT,labelIDsT] = groupcounts(keptPairs(:,2));   % Identify ID repeats in frame 1 among overlap ID pairs
    truncatedLabels = labelIDsT(labelCountsT>1);                      % Get list of IDs in frame 1 that repeat
    % Iterate through each repeated label and assign appropriate IDs
    for labelInd = 1:numel(truncatedLabels)
        labelIndices = find(keptPairs(:,2) == truncatedLabels(labelInd));
        updateIDs = nextID + (1:numel(labelIndices)) - 1;
        % If truncating trajectories upon truncation event
        if truncateMergers == 1
            nextID = nextID + numel(labelIndices);
        % If continuing trajectories through truncations, assign parent ID
        % to largest child
        else
            truncChildrenIDs = keptPairs(labelIndices,1);          % Get IDs of children for current truncation
            volsOfChildren = objVols2(ismember(objIDs2,truncChildrenIDs));       % Get volumes of children
            [~, largestVolInd] = max(volsOfChildren);           % Find largest
            updateIDs(largestVolInd:end) = updateIDs(largestVolInd:end) - 1;
            updateIDs(largestVolInd) = truncatedLabels(labelInd);          % Assign ID of largest
            nextID = nextID + numel(labelIndices) - 1;
        end
        keptPairs(labelIndices,2) = updateIDs;
    end
    
% Generate a mapping vector for inheritance
    mapVector = zeros(numel(unique(labeledObjs2)) - ismember(0,labeledObjs2),1);
        % Assign indices corresponding to frame two labels with non-degenerate
        % object labels from frame 1
    mapVector(keptPairs(:,1)) = keptPairs(:,2);

% Assign IDs to nucleated/new objects
    if newObjsBool == 1
        % Find nucleated/new objects in new time point
            % Compare labels at indices in frame 2 that overlap with zeros in frame 
            % 1 to the list of all unique labels in frame 2. Any new labels must be
            % accounted for and added
        firstPassNewObjs = unique(labeledObjs2(~frameOneLogical));
        uniqueNewObjs = firstPassNewObjs(~ismember(firstPassNewObjs,keptPairs(:,1)));
            % Remove 0
        uniqueNewObjs = uniqueNewObjs(uniqueNewObjs~=0);
            % Assign indices to new objects
        mapVector(uniqueNewObjs) = (1:numel(uniqueNewObjs)) + nextID;
        nextID = nextID + numel(uniqueNewObjs);
        % mapVector(uniqueNewLabels) = (1:numel(uniqueNewLabels)) + size(keptPairs,1);
    end

% Assign inheritance to trajectories, then save
        % Duplicate frame 2, then get vector of labels > 0
    inheritMat = labeledObjs2;
    nonzeroLabels = inheritMat(frameTwoLogical);
        % Map using map vector of indices in duplicated inheritance matrix
    inheritMat(frameTwoLogical) = mapVector(nonzeroLabels);
    % NOTE: vector of a scalar array returns an array with mapped vector contents
    
    % Save, if requested
    if saveBool == 1
        if tInd == 1
            currT = selectTimes(tInd);
            save3DTiff(uint16(labeledObjs1),fullfile(saveDir,sprintf(saveName,currT)));
        end
        save3DTiff(uint16(inheritMat),fullfile(saveDir,sprintf(saveName,nextT)));    
        % Save masked images and connected component objects
        if maskBool == 1
            if tInd == 1
                currT = selectTimes(tInd);
                save3DTiff(uint16(zeros(size(inheritMat))),fullfile(saveDir,'Masked Blobs',sprintf(saveName,currT)));
                [currCC,storeStruct] = blobMat2CCProps(false(size(inheritMat)),ccFields);
                save(fullfile(saveDir,'Masked CCs',sprintf('objIDs_T%06i.mat',currT)),'currCC');
                storeStruct(tInd).FrameNum = currT;
            end
            maskedMat = consMatLnB(inheritMat,~logical(frameOne));
            save3DTiff(uint16(maskedMat),fullfile(saveDir,'Masked Blobs',sprintf(saveName,nextT)));
            [currCC,storeStruct] = blobMat2CCProps(logical(maskedMat),ccFields,storeStruct);
            save(fullfile(saveDir,'Masked CCs',sprintf('objIDs_T%06i.mat',nextT)),'currCC');
            storeStruct(tInd+1).FrameNum = nextT;
        end
    end
            
% Assign frame two info to frame 1
    frameOneLogical = frameTwoLogical;
    labeledObjs1 = inheritMat;
    indVec1 = find(frameOneLogical); 

% end

if maskBool == 1
    storeStruct(1).Centroid = [0 0 0];
    storeStruct(1).Volume = 0;
    storeStruct(1).PrincipalAxisLength = [0 0 0];
    save(fullfile(saveDir,'Masked CCs','storageStruct.mat'),'storeStruct');
end


