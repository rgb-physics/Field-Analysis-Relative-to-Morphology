% Takes in directory of blob objects saved tif per time point. Checks for
% overlaps in object indices between consecutive time points, samples
% object labels of each, then samples unique pairs of labels between the
% two time points. Optionally reconstructs tifs with blobs labeled per
% object ancestry/inherited blob index 
% This script assumes minimal object drift; object overlap between frames
% is assumed enough for inheritence
% Rémi Boros, 2024-06-17

% dataDir = '<redacted original absolute path>';
dataDir = 'Session 88';
dataName = 'E1_BlobMat_t%03i.tif';
% saveDir = '<redacted original absolute path>';
saveDir = 'Session 88, Exp 1';
saveName = 'T%06i_trackedIDs.tif';

selectTimes = 23:70;
baseShftOut = 300;
shftStep = 25;
% resetNewID = 0;

saveBool = 1;
newObjsBool = 1;            % Generate trajectories for nucleating objects 
truncateMergers = 0;        % End trajectories when drops merge (new traj for child) - otherwise, inheritance goes to largest boject
truncateSplitters = 0;      % End trajectories when drops split (new trajs for each child)
maskBool = 0;

uniqueFrame1 = 0;

ccFields = {'Centroid','Area','PixelIdxList','MajorAxisLength','MinorAxisLength'};
% ccFields = {'Centroid','Volume','VoxelIdxList','PrincipalAxisLength'};
%% Pick a frame 1 - load data
% % Same folder
% frameOneLogical = logical(tiffreadVolume(fullfile(dataDir,sprintf(dataName,selectTimes(1)))));
% dataDir1 = '<redacted original absolute path>';
dataDir1 = '';
dataName1 = 'eroded_T215.tif';

%% Make directory
if ~exist(saveDir,'dir')
    mkdir(saveDir);
end
if ~exist(fullfile(saveDir,'Masked Blobs'),'dir')
    mkdir(fullfile(saveDir,'Masked Blobs'));
    mkdir(fullfile(saveDir,'Masked CCs'));
end

%% Iterate over time
for tInd = 1:(numel(selectTimes) - 1)

    % Load data sets
    nextT = selectTimes(tInd+1);
    frameTwo = tiffreadVolume(fullfile(dataDir,sprintf(dataName,nextT)));

    % Prepare data labels and logical matrices
    if tInd == 1
        if uniqueFrame1 == 1
            labeledObjs1 = double(tiffreadVolume(fullfile(dataDir1,dataName1)));
            frameOneLogical = logical(labeledObjs1);
        else
            frameOne = tiffreadVolume(fullfile(dataDir,sprintf(dataName,selectTimes(1))));
            frameOneLogical = logical(frameOne);
            labeledObjs1 = bwlabeln(frameOneLogical);
        end
        indVec1 = find(frameOneLogical); 
        nextID = max(labeledObjs1(:)) + 1;
    end
    [objVols1, objIDs1] = groupcounts(labeledObjs1(labeledObjs1>0));
    % Prepare frame two data
    frameTwoLogical = logical(frameTwo);
    labeledObjs2 = bwlabeln(frameTwoLogical);
    indVec2 = find(frameTwoLogical);   
    [objVols2, objIDs2] = groupcounts(labeledObjs2(labeledObjs2>0));

    % Get overlapping indices between frames
    overlapInds = indVec1(ismember(indVec1,indVec2));
    % Get object labels at overlapping inds over consecutive time points
    objectLabelPairs = [labeledObjs2(overlapInds),labeledObjs1(overlapInds)];
    uniqueObjectPairs = unique(objectLabelPairs,"rows");
    ogPairs = uniqueObjectPairs;

% Assign IDs to merged objects; T_i objects are parents, T_i+1 is the child 
    % Generate new trajectory inheritance for merger events
    [labelCountsM,labelIDsM] = groupcounts(uniqueObjectPairs(:,1));   % Identify ID repeats in frame 2 among overlap ID pairs
    mergerLabels = labelIDsM(labelCountsM>1);                         % Get list of IDs in frame 2 that repeat (multiple objects "map" to a single object)
    % Iterate through each repeated label and assign appropriate IDs
    for currLabel = 1:numel(mergerLabels)
        currInds = find(uniqueObjectPairs(:,1) == mergerLabels(currLabel));
        % If truncating trajectories upon merger event
        if truncateMergers == 1
            updateIDs = nextID;
            nextID = nextID + 1;
        % If continuing trajectories through mergers, keep ID of larger parent
        else
            mergerParentIDs = uniqueObjectPairs(currInds,2);
            volsOfParents = objVols1(ismember(objIDs1,mergerParentIDs));      % Fewer numbers of objects than max ID as time progresses -> get indices of appropriate objects
            [~, largestVolInd] = max(volsOfParents);
            updateIDs = mergerParentIDs(largestVolInd);
        end
        uniqueObjectPairs(currInds,2) = updateIDs;
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

% Assign IDs to truncated objects; T_i is single parent, T_i+1 are children
% (flipped case of mergers)
    % Generate new trajectory inheritance for merger events
    [labelCountsT,labelIDsT] = groupcounts(keptPairs(:,2));   % Identify ID repeats in frame 1 among overlap ID pairs
    truncatedLabels = labelIDsT(labelCountsT>1);                      % Get list of IDs in frame 1 that repeat
    % Iterate through each repeated label and assign appropriate IDs
    for currLabel = 1:numel(truncatedLabels)
        currInds = find(keptPairs(:,2) == truncatedLabels(currLabel));
        updateIDs = nextID + (1:numel(currInds)) - 1;
        % If truncating trajectories upon merger event
        if truncateMergers == 1
            nextID = nextID + numel(currInds);
        % If continuing trajectories through truncations, assign parent ID
        % to largest child
        else
            truncChildrenIDs = keptPairs(currInds,1);          % Get IDs of children for current truncation
            volsOfChildren = objVols2(ismember(objIDs2,truncChildrenIDs));       % Get volumes of children
            [~, largestVolInd] = max(volsOfChildren);           % Find largest
            updateIDs(largestVolInd:end) = updateIDs(largestVolInd:end) - 1;
            updateIDs(largestVolInd) = truncatedLabels(currLabel);          % Assign ID of largest
            nextID = nextID + numel(currInds) - 1;
        end
        keptPairs(currInds,2) = updateIDs;
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
            outMat = (labeledObjs1*shftStep + baseShftOut) ...
                - baseShftOut*consMatLnB(ones(size(labeledObjs1)),~logical(labeledObjs1));
            save3DTiff(uint16(outMat),fullfile(saveDir,sprintf(saveName,currT)));
            % save3DTiff(uint16(labeledObjs1),fullfile(saveDir,sprintf(saveName,currT)));
        end
        outMat = (inheritMat*shftStep + baseShftOut) ...
            - baseShftOut*consMatLnB(ones(size(inheritMat)),~logical(inheritMat));
        save3DTiff(uint16(outMat),fullfile(saveDir,sprintf(saveName,nextT)));    
        % save3DTiff(uint16(inheritMat),fullfile(saveDir,sprintf(saveName,nextT)));    
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

end

if maskBool == 1
    storeStruct(1).Centroid = [0 0 0];
    storeStruct(1).Volume = 0;
    storeStruct(1).PrincipalAxisLength = [0 0 0];
    save(fullfile(saveDir,'Masked CCs','storageStruct.mat'),'storeStruct');
end


