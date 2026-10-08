%% Using trajStruct, add intensity histograms 
% ccDir = '<redacted original absolute path>';
ccDir = 'Session 35, Exp 1';
% trajDir = '<redacted original absolute path>';
trajDir = 'Session 35, Exp 1';
% tifDir = '<redacted original absolute path>';
tifDir = 'Session 35, Exp 1';
% saveDir = '<redacted original absolute path>';
saveDir = 'Session 35, Exp 1';
% visBlobDir = '<redacted original absolute path>';
visBlobDir = 'Session 35, Exp 1';
visBlobNames = 'selBlobs_T%06i.tif';
intSaveDir = fullfile(saveDir, 'Intensity Histograms');
ccNameForm = 'objIDs_T%06i.mat';
trajName = 'TrajectoryStructure.mat';
tifNameForm = 'Time%06i_16bitcropped.tif';
% globalInfoDir = '<redacted original absolute path>';
globalInfoDir = 'Session 35, Exp 1';
load(fullfile(globalInfoDir,'globalIntVolStats.mat')); 
trajCutOff = 15;
minCorn = [300, 300, 50];
maxCorn = [500, 500, 85];
binMax = 10000; binNum = 200;
bins = 0:round(binMax/binNum):binMax;
histFieldName = 'IntHistT%i';
timeSize = 30;
pixSize = 2*11/20;

%% load trajectories
load(fullfile(trajDir,trajName));
trajLens = structFieldSizes(trajStruct,'Frames');
longTrajs = trajStruct(trajLens>=trajCutOff);
trajInds = 1:numel(trajStruct);
longTrajInds = trajInds(trajLens>=trajCutOff);

%% Select trajectories within xyz bounds
changeFields = fieldnames(trajStruct);
choiceField = 'Cens';
selTrajs = structCutOffThresh(longTrajs, choiceField, minCorn, maxCorn, changeFields);
exTrajs = logical(structFieldSizes(selTrajs,choiceField));
selTrajs = selTrajs(exTrajs);
selTrajInds = longTrajInds(exTrajs);

%% Store binned intensities at each time
selectTimes = unique(vertcat(selTrajs.Frames));
meanInts = vertcat(timeStore.meanInt);
bleachRate = meanInts/max(meanInts);

for tInd = 1:numel(selectTimes)
    currT = selectTimes(tInd);
    currBleach = bleachRate(tInd);
%     currTif = tiffreadVolume(fullfile(tifDir,sprintf(tifNameForm,currT)));
    currTif = tiffreadVolume(fullfile(tifDir,sprintf(tifNameForm,currT)))/currBleach;
    load(fullfile(ccDir, sprintf(ccNameForm,currT)));
tic
    for trajInd = 1:numel(selTrajs)
        currTraj = selTrajs(trajInd);
        objIndInTraj = currTraj.Frames == currT;
        if logical(sum(objIndInTraj))
            currObjIDs = currTraj.objIDs;
            currPixVals = currTif(currCC.PixelIdxList{currObjIDs(objIndInTraj)});
            binCounts = histcounts(currPixVals, bins);
            selTrajs(trajInd).(sprintf(histFieldName,currT)) = binCounts;
        end
    end
toc

end

%% Plot stored values
colorsMap = meldNcolors([0 0 1; 1 0 0], numel(selectTimes));
histShift = 50;
maxShift = histShift*(selectTimes(end)+2);

for trajInd = 1:numel(selTrajInds)
    currTraj = selTrajs(trajInd);
    trajFrames = vertcat(currTraj.Frames);
    figure
    for tInd = 1:numel(selectTimes)
    
        currT = selectTimes(tInd);
        currField = sprintf(histFieldName,currT);
        currInd = ismember(trajFrames,currT);
        if logical(sum(currInd))
            subplot(1,2,1)
            plot(bins(2:end), currTraj.(currField)+histShift*tInd, 'Color', colorsMap(tInd,:));
            hold on
            ylim([0 maxShift])
            xlabel('Intensity')
            ylabel('Counts (shifted per time)')
            title(sprintf('Int. Dist. in Drop %i',selTrajInds(trajInd)))
            subplot(1,2,2)
            scatter(currT*timeSize, currTraj.Vol(currInd)*pixSize^3, 16, colorsMap(tInd,:), 'filled');
            hold on
            xlim([0 selectTimes(end)*timeSize])
            ylim([0 10000])
            xlabel('Time (s)')
            ylabel('Drop Volume (um^3)')
            title(sprintf('Drop %i Vol. over time', selTrajInds(trajInd)))
        end
    
    end
    saveas(gca,fullfile(intSaveDir, sprintf('IntHist%06i', selTrajInds(trajInd))));
    saveas(gca,fullfile(intSaveDir, sprintf('IntHist%06i.png', selTrajInds(trajInd))));
    close
end

%% Plot traj volumes over time
figure
for trajInd = 1:numel(selTrajInds)
    currTraj = selTrajs(trajInd);
    loglog(currTraj.Frames, (currTraj.Vol).^(2/3))
    hold on
end

%% Store binned "concentration" at each time
selectTimes = unique(vertcat(selTrajs.Frames));
meanInts = vertcat(timeStore.meanInt);
bleachRate = meanInts/max(meanInts);
selTrajs(1).MeanConc = [];
selTrajs(1).TotInt = [];

for tInd = 1:numel(selectTimes)
    currT = selectTimes(tInd);
    currBleach = bleachRate(tInd);
%     currTif = tiffreadVolume(fullfile(tifDir,sprintf(tifNameForm,currT)));
    currTif = tiffreadVolume(fullfile(tifDir,sprintf(tifNameForm,currT)))/currBleach;
    load(fullfile(ccDir, sprintf(ccNameForm,currT)));
tic
    for trajInd = 1:numel(selTrajs)
        currTraj = selTrajs(trajInd);
        objIndInTraj = currTraj.Frames == currT;
        if logical(sum(objIndInTraj))
            currObjIDs = currTraj.objIDs;
            currPixVals = currTif(currCC.PixelIdxList{currObjIDs(objIndInTraj)});
            selTrajs(trajInd).MeanConc(end+1) = sum(currPixVals)/currTraj.Vol(objIndInTraj);
            selTrajs(trajInd).TotInt(end+1) = sum(currPixVals);
        end
    end
toc

end

%% Plot traj volumes over time
figure
for trajInd = 1:numel(selTrajInds)
    currTraj = selTrajs(trajInd);
    loglog(currTraj.Frames, currTraj.TotInt./(currTraj.Vol').*(currTraj.Vol').^(1/3))
    hold on
end

%% Plot tot intensities and mean conc per time
figure
for trajInd = 1:numel(selTrajInds)
    currTraj = selTrajs(trajInd);
    subplot(1,2,1)
    plot(currTraj.Frames*timeSize, currTraj.TotInt)
    ylabel('Total Intensity')
    hold on
    subplot(1,2,2)
    plot(currTraj.Frames*timeSize, currTraj.MeanConc)
    ylabel('Mean Intensity/Volume')
    hold on
end

%% Save sub selection of trajectories with tif values
% objDir = '<redacted original absolute path>';
objDir = 'Session 35, Exp 1';
objNameForm = 'objIDs_T%06i.mat';
selectTimes = unique(vertcat(selTrajs.Frames));
meanInts = vertcat(timeStore.meanInt);
bleachRate = meanInts/max(meanInts);

for tInd = 1:numel(selectTimes)
    currT = selectTimes(tInd);
    currBleach = bleachRate(tInd);
%     currTif = tiffreadVolume(fullfile(tifDir,sprintf(tifNameForm,currT)));
    currTif = tiffreadVolume(fullfile(tifDir,sprintf(tifNameForm,currT)))/currBleach;
    load(fullfile(objDir, sprintf(objNameForm,currT)));
%     load(fullfile(ccDir, sprintf(ccNameForm,currT)));
tic
    currObjs = zeros(size(currTif));
    for trajInd = 1:numel(selTrajs)
        currTraj = selTrajs(trajInd);
        objIndInTraj = currTraj.Frames == currT;
        if logical(sum(objIndInTraj))
            currObjIDs = currTraj.objIDs;
            currPixIDs = (objIDs.pixIDs{currObjIDs(objIndInTraj)});  % Add to vector, then construct matrix in time loop instead of iteratively in traj loop                
            currObjs = consMatLnB(currTif, currPixIDs) + currObjs;
        end
    end
toc
    save3DTiff(uint16(currObjs), fullfile(visBlobDir,sprintf(visBlobNames,currT)));

end

%% Select trajectories

%% Save tifs
bimodalTrajs = [17612, 17623, 17649, 17885, 18721, 19073, 19139, 19583, 19770, 20508, 20540, 23375, 23983];
otherTrajs = selTrajInds(~ismember(selTrajInds, bimodalTrajs));
% saveDir = '<redacted original absolute path>';
saveDir = 'Session 35, Exp 1';
saveName = '%s_T%06i_objs.tif';
% objDir = '<redacted original absolute path>';
objDir = 'Session 35, Exp 1';
objNameForm = 'objIDs_T%06i.mat';
selectTimes = unique(vertcat(selTrajs.Frames));
meanInts = vertcat(timeStore.meanInt);
bleachRate = meanInts/max(meanInts);

for tInd = 1:numel(selectTimes)
    currT = selectTimes(tInd);
    currBleach = bleachRate(tInd);
%     currTif = tiffreadVolume(fullfile(tifDir,sprintf(tifNameForm,currT)));
    currTif = tiffreadVolume(fullfile(tifDir,sprintf(tifNameForm,currT)))/currBleach;
    load(fullfile(objDir, sprintf(objNameForm,currT)));
%     load(fullfile(ccDir, sprintf(ccNameForm,currT)));
tic
    currPixIDsBimodal = [];
    currPixIDsOther = [];
    for trajInd = 1:numel(selTrajs)
        currTraj = selTrajs(trajInd);
        objIndInTraj = currTraj.Frames == currT;
        if logical(sum(objIndInTraj))
            currObjIDs = currTraj.objIDs;
            if sum(ismember(bimodalTrajs,selTrajInds(trajInd) ))
                currPixIDsBimodal = [currPixIDsBimodal; (objIDs.pixIDs{currObjIDs(objIndInTraj)})]; 
            else
                currPixIDsOther = [currPixIDsOther; (objIDs.pixIDs{currObjIDs(objIndInTraj)})];
            end
        end
    end
    currObjsBim = consMatLnB(currTif, currPixIDsBimodal);
    currObjsOth = consMatLnB(max(min(currTif+25000,2^16-1),0), currPixIDsOther);
    save3DTiff(uint16(currObjsBim), fullfile(saveDir,sprintf(saveName,'bimodalObjs',currT)));
    save3DTiff(uint16(currObjsOth), fullfile(saveDir,sprintf(saveName,'otherObjs',currT)));
toc
end

%% Color code trajectories and identify all objects below cutoff volume; color code based on trajectory age OR trajectory start
% storeDir = '<redacted original absolute path>';
storeDir = 'Session 35, Exp 1';
load(fullfile(storeDir,"storageStruct.mat"));
subTimes = 1:30;
objsInFrame = structFieldSizes(storeStruct, 'Vol');
cutOff2 = 6;

longTrajs2 = trajStruct(trajLens>=cutOff2);
trajInds2 = 1:numel(trajStruct);
longTrajInds2 = trajInds2(trajLens>=cutOff2);

%% Add trajectory start times
for trajInd = 1:numel(longTrajInds2)
    longTrajs2(trajInd).StartFrame = longTrajs2(trajInd).Frames(1);
    longTrajs2(trajInd).EndFrame = longTrajs2(trajInd).Frames(end);
end

%% 
% saveDir = '<redacted original absolute path>';
saveDir = 'Session 35, Exp 1';
saveNameForm = 'Sub%i_Vols_T%06i.tif';
volCutOff = 5000;
trajIndTracker = vertcat(longTrajs2.StartFrame);
for tInd = 1:numel(subTimes)
    
    currT = subTimes(tInd);
    currBleach = bleachRate(tInd);
    load(fullfile(objDir, sprintf(objNameForm,currT)));

tic
    currTPix = cell(1,numel(subTimes));
    for trajInd = 1:numel(longTrajs2)
        % Check that trajectory falls within time range
        if (subTimes(tInd) >= longTrajs2(trajInd).StartFrame) && (subTimes(tInd) <= longTrajs2(trajInd).EndFrame)
            if trajIndTracker(trajInd) > 0               % Make sure trajectory hasn't been removed from list
                currTraj = longTrajs2(trajInd);
                objIndInTraj = currTraj.Frames == currT;
                if logical(sum(objIndInTraj))
                    currObjID = currTraj.objIDs(objIndInTraj);
                    if storeStruct(currT).Vol(currObjID) < volCutOff
                        currPixIDs = objIDs.pixIDs{currObjID};
                        currTPix{currTraj.StartFrame} = [currTPix{currTraj.StartFrame}; currPixIDs];
                    else
                        trajIndTracker(trajInd) = 0;
                    end
                end
            end
        end
    end

    currObjs = zeros(size(currTif));
    for tInd2 = min(trajIndTracker(trajIndTracker>0)):tInd
        currT2 = subTimes(tInd2);
        currObjs = currObjs + consMatLnB(ones(size(currObjs))*currT2, currTPix{tInd2});
    end
    save3DTiff(uint16(currObjs*100), fullfile(saveDir,sprintf(saveNameForm,volCutOff,currT)));
toc
end