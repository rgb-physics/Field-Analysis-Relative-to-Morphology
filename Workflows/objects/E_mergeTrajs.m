% From time object trajectory table, stitch together merger objects using
% end frames in trajectories and start frames in trajectories

%% Load data
% totDir = '<redacted original absolute path>';
totDir = 'Session 35, Exp 1';
totName = 'TimeObjectTrajectory_Table.mat';
% objDir = '<redacted original absolute path>';
objDir = 'Session 35, Exp 1';
objNameForm = 'objIDs_T%06i.mat';
load(fullfile(totDir,totName));
totArray = table2array(totTable);
minTrajLen = 3;

%% Get length of each trajectory
trajIDs = unique(totArray(:,3));
trajLens = histcounts(totArray(:,3), trajIDs);

%% Find start and end frames of each trajectory
[~,trajSortInds] = sort(totArray(:,3));         %sort totTable by trajectory
sortedArray = totArray(trajSortInds,:);         %sort totArray with the above sorting order
%start and end frames are indexed by the cumulative sum of all trajectory lengths in this sorted format
trajStarts = [1 1 1; sortedArray(cumsum(trajLens(1:end-1)) + 1,:)];
trajEnds = sortedArray(cumsum(trajLens),:);   

%% Object IDs of trajs ending at time i and starting at i+1
tInd = 20;
endTrajInds = trajEnds(:,1) == tInd;
endIDs = trajEnds(endTrajInds,2);
startTrajInds = trajStarts(:,1) == tInd + 1;
startIDs = trajEnds(startTrajInds,2);

%% Assume objIds are saved as a struct called objIDs
endTimeObjs = load(fullfile(objDir,sprintf(objNameForm,tInd)));
endTimeObjs = endTimeObjs.objIDs;
startTimeObjs = load(fullfile(objDir,sprintf(objNameForm,tInd+1)));
startTimeObjs = startTimeObjs.objIDs;

%% Load all relevant pixels from objID objects
endObjInds = vertcat(endTimeObjs.pixIDs{endIDs});
startObjInds = vertcat(startTimeObjs.pixIDs{startIDs});

%% Load all pixels in both frames
allInds0 = vertcat(endTimeObjs.pixIDs{:});
allInds1 = vertcat(startTimeObjs.pixIDs{:});

%% Load tifs
% tifDir = '<redacted original absolute path>';
tifDir = 'Session 35, Exp 1';
tifName = 'Time%06i_16bitcropped.tif';
tif0 = tiffreadVolume(fullfile(tifDir,sprintf(tifName,tInd)));
tif1 = tiffreadVolume(fullfile(tifDir,sprintf(tifName,tInd+1)));

%% 
endObjs = consMatLnB(ones(size(tif0)), endObjInds);
startObjs = consMatLnB(ones(size(tif0)), startObjInds);
t0Objs = consMatLnB(ones(size(tif0)), allInds0);
t1Objs = consMatLnB(ones(size(tif0)), allInds1);

%% Cutoff?
allTrajIDs = trajIDs; allTrajEnds = trajEnds;
toKeepInds = trajLens >= minTrajLen;
trajIDs = trajIDs(toKeepInds);



