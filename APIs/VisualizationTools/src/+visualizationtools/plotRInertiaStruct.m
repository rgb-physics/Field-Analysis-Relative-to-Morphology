%% Quick and dirty: plot quantities stored in sortedMat
% sortedMat is calculated from segmentations and intensity data in
% blobPropsFromTrajs_R_Inertia.m
% 2026-06-01 - Rémi Boros

% dataDir = '<redacted original absolute path>';
dataDir = 'Session 84';
dataName = 'ALL_trajSorted_RMin_Anisotropy.mat';

%% Load
load(fullfile(dataDir,dataName));
unqTs = unique([statStruct(:).Frame]);

%% Plot Number vs. Time
tVec = [statStruct(:).Frame];
idVec = [statStruct(:).BlobID];
rVec = tVec;    faVec = rVec;   sphVec = faVec;
meanR = unqTs;  meanFA = unqTs; meanSph = unqTs;
meanRObj = unqTs;   meanFAObj = unqTs;  meanSphObj = unqTs;
numObjs = unqTs;    
skelVol = tVec;
maxSamp = max(structFieldSizes(statStruct,'skelSubInds'));        % used for averaging, important if sampled skeleton index number was capped

% Iterate over time, calculate mean r and anisotropy for each blob,
% calculate mean quantities over time
for tInd = 1:numel(unqTs)

    currT = unqTs(tInd);
    currLogic = tVec == currT;
    idInds = find(currLogic);

    % Calculate mean values for each blob
    for index = 1:sum(currLogic)        
        currInd = idInds(index);
        rVec(currInd) = mean(statStruct(currInd).MinAxStats);
        faVec(currInd) = mean(statStruct(currInd).FAs);
        sphVec(currInd) = mean(statStruct(currInd).Sphs);
        skelVol(currInd) = numel(statStruct(currInd).MinAxStats);
    end

    % Calculate mean property at current time point over all objects
    meanRObj(tInd) = mean(rVec(currLogic));
    meanFAObj(tInd) = mean(faVec(currLogic));
    meanSphObj(tInd) = mean(sphVec(currLogic));

    % Calculate mean property at current time weighted by sample number
    if sum(currLogic) > 1
        sum(currLogic);
    end
    voxWghts = skelVol(idInds);     cappedWghts = max(voxWghts,maxSamp);
    meanR(tInd) = sum(rVec(currLogic).*voxWghts)/sum(voxWghts);
    meanFA(tInd) = sum(faVec(currLogic).*cappedWghts)/sum(cappedWghts);
    meanSph(tInd) = sum(sphVec(currLogic).*cappedWghts)/sum(cappedWghts);
    numObjs(tInd) = numel(idInds);

end

%% Plots

figure
scatter((unqTs-25)*.5,meanRObj,'filled')
xlim([-13 13])
ylim([0 15])
xlabel('Time (min)')
ylabel('Structure Half-Width (\muM)')
set(gca,'FontSize',15)
box on

figure
scatter((unqTs-25)*.5,meanFA,'filled')
xlim([-13 13])
ylim([0 1])
ylabel('Fractional Anisotropy')
hold on
yyaxis right
scatter((unqTs-25)*.5,meanSph,'filled')
temp=gca;
temp.YColor ='k';
xlabel('Time (min)')
ylabel('Spherocity')
set(gca,'FontSize',15)
box on
legend('Fractional Anisotropy','Spherocity')

figure
scatter((unqTs-25)*.5,numObjs,'filled')
xlim([-13 13])
xlabel('Time (min)')
ylabel('Number of Objects')
set(gca,'FontSize',15)
box on

