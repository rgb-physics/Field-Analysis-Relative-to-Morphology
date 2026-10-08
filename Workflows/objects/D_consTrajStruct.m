% What do we want in trajectory structure?
% each object a trajectory
% has Time, objectID, Volume, Area, total length, *intensity hists*
% Storage structure and totTable must agree in object IDs. The same is true
% for objID structures
%% From storage structure and totTable
% storeDir = '<redacted original absolute path>';
storeDir = 'Session 56, Exp 1';
% tifDir = 'Session 35, Exp 1';
saveDir = storeDir;
objNameForm = 'IDCC_T%06i.mat';
% tifNameForm = 'Time%06i_16bitcropped.tif';
load(fullfile(storeDir, 'storageStruct.mat'));
load(fullfile(storeDir, 'TimeObjectTrajectory_Table.mat'));

totArray = table2array(totTable);
selectTimes = 1:50;

% %% Load a tif
% testTif = tiffreadVolume(fullfile(tifDir,sprintf(tifNameForm,1)));
% tifDims = size(testTif);

%% Simple totTable info: by default totTable is sorted by time
trajStruct = tot2ts(totArray);

%% Add desired fields stored in storeStruct
desFields = {'Cens','Vol'};
[trajStruct] = addFieldStruct2Traj(storeStruct,trajStruct,desFields);

%% Add trajStruct info from objID structures
tempStruct = struct();
desFields = {'SurfaceArea',"Centroid",'EigenVectors'};
tic
for tInd = 1:numel(selectTimes)
    load(fullfile(storeDir,sprintf(objNameForm,tInd)))
    currProps = regionprops3(currCC,desFields);
    for fieldInd = 1:numel(desFields)
        tempStruct(tInd).(desFields{fieldInd}) = table2cell(currProps(:,fieldInd));
    end
end
toc
% addFieldStruct

%% Add trajStruct info from CC structures only for desired trajectories
% Need to break this down later
tempStruct = struct();
desTrajs = 1:10;
objVecStoreFrame = [];
subTrajs = trajStruct(desTrajs);
subObjs = vertcat(subTrajs.objIDs);
subTimes = vertcat(subTrajs.Frames);
desFields = {'SurfaceArea',"Centroid",'EigenVectors'};
tic
for tInd = 1:numel(selectTimes)
    currT = selectTimes(tInd);
    % Make sub CC object
    load(fullfile(storeDir,sprintf(objNameForm,tInd)))
    currObjs = subObjs(subTimes == currT);
    numObjs = numel(currObjs);
    temp = currCC; temp.NumObjects = numObjs; temp.PixelIdxList = currCC.PixelIdxList(currObjs);
    %Iterate through fields
    for fieldInd = 1:numel(desFields)
        currField = desFields{fieldInd};
        % FUNCTION IS HERE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        currProps = regionprops3(temp,currField);
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        tempStruct(tInd).(currField) = table2cell(currProps);
    end

    tempStruct(tInd).ogIDs = currObjs;
    tempStruct(tInd).trajIDs = subTrajIDs(subTimes == currT);

    objVecStoreFrame((end+1):(end+numObjs)) = 1:numObjs;

end
% Convert objIDs from time frame to traj frame, then make totArray
% build a new totTable
[~, timeSort] = sort(subTimes);
indxVec = 1:numel(timeSort);
[~, reverseSort] = sort(indxVec(timeSort));
objVec = objVecStoreFrame(reverseSort);
timeVec = subTimes;
trajVec = structLenVec(subTrajs, 'Frames');
newTOT = [timeVec(:), objVec(:), trajVec(:)];

% Add desired fields to trajectory
tempTOT = tot2ts(newTOT);
desFields = {'ogIDs', 'SurfaceArea'};
tempTrajs = addFieldStruct2Traj(tempStruct,tempTOT,desFields);
for fieldInd = 1:numel(desFields)
    [trajStruct(desTrajs).(desFields{fieldInd})] = deal(tempTrajs(desTrajs).(desFields{fieldInd}));
end

%% Save
save(fullfile(saveDir, 'TrajectoryStructure.mat'), 'trajStruct');
