%% Calc mean order parameter from rp3D in binned domains
% rName contains tif with deltaR bin encoded at each index; can be distance
% transform or in out on matrix
% 2025-02-16 - Rémi Boros

% filDataDir = '<redacted original absolute path>';
filDataDir = 'Session 88, Exp 5';
filDataName = 'Filament Statistics %03i.mat';
% rDir = '<redacted original absolute path>';
rDir = 'Session 88, Exp 5';
rName = 'T%03i_CleanInOnOut.tif';
concatFils = 'Concatenated_3DFilDataNew.mat';
concatRs = 'Concatenated_rsAtCensNew.mat';

% filDataDir = 'Session 88, Exp 5';
% filDataName = 'Filament Statistics %03i.mat';
% rDir = 'Session 88, Exp 5';
% rName = 'T%03i_CleanInOnOut.tif';
% concatFils = 'Concatenated_3DFilDataNew.mat';
% concatRs = 'Concatenated_rsAtCensNew.mat';

ccField = 'rp3D';
% rField = 'DeltaR';
rField = 'fieldAtCens';
selTimes = 1:57;
rBins = [-Inf 100 220 Inf];     % Units are whatever rFiles are stored in
cutLen = 4; cutVol = 8; cutAR = 1.5;
cutZ = 0.4;
ogPixSc = [0.55 0.55 0.7];
ilstkScale = ogPixSc/max(ogPixSc);
ilstkPixSc = ogPixSc./ilstkScale;

deltaT = 30/60;

colorMat = min(1,[[100,0,100]; [242, 134, 144]; [0 200 110] ]/255); % watermelon
% colorMat = min(1,[[10,0,105]; [150, 100, 170]; [150 220 190] ]/255); % minty night
% colorMat = min(1,[[100,0,100];  [230, 30, 165];  [0 180 100] ]/255); % watermelon
dispBool = 0;

%% Concatenate data
if ~exist(fullfile(filDataDir,concatFils),'file')
    fData = concatTablesOverT(filDataDir,filDataName,selTimes,ccField,1,concatFils);
    temp = concatTablesOverT(filDataDir,filDataName,selTimes,rField,1,concatRs);
    fData.(rField) = temp.(rField);
else
    fData = load(fullfile(filDataDir,concatFils)).('superTable');
    load(fullfile(filDataDir,concatRs));
    fData.(rField) = superTable.(rField);
end
% Calculate additional fields
zAligns = fData.("Directors")(:,3);

%% Get order parameters from directors and gradients
% NOTE: must vector normalize gradients
fils = fData.('Directors');
fils3D = fils.*ilstkScale;
fils3D = fils3D./vecnorm(fils3D')';
grads = fData.('GradsAtCens');      % 1/units of dense; if cubic, just normalize
grads3D = grads./vecnorm(grads')';
fDg3D = dot(fils3D',grads3D')';
order3D = min(1,max(-0.5,1/2*(3*fDg3D.^2 - 1)));
% THESE LOOK GOOD - 3D should be corrected in z?
fils2D = fils(:,1:2)./vecnorm(fils(:,1:2)')';
grads2D = grads(:,1:2)./vecnorm(grads(:,1:2)')';
fDg2D = dot(fils2D',grads2D')';
order2D = min(1,max(-1,(1/1*(2*fDg2D.^2 - 1))));

%% Define logic
lenLogic = fData.("Lengths") > cutLen;
volLogic = fData.("Volume") > cutVol;
arLogic = fData.AspectRatios > cutAR;
psfLogic = zAligns < cutZ;

%% 2D order parameter, counts, and histograms
selLogic = lenLogic & volLogic & arLogic & psfLogic;
selField = order2D;
titleStr = '2D Order - Filtered';
% Instantiate storage objects
uniqueRs = unique(fData.(rField));
meanVals = zeros(numel(selTimes),numel(uniqueRs));
stdVals = meanVals; medVals = meanVals; numStore = meanVals;

% Isolate times
for tInd = 1:numel(selTimes)
    currT = selTimes(tInd);
    tLogic = fData.("Frame") == currT;
    % Isolate r bins
    for index = 1:numel(uniqueRs)
        currR = uniqueRs(index);
        rLogic = fData.(rField) == currR;
        % Concatenate logic
        totLogic = tLogic & rLogic & selLogic;
        % Get order params
        subField = selField(totLogic);
        % Store 
        meanVals(tInd,index) = mean(subField);
        medVals(tInd,index) = median(subField);
        stdVals(tInd,index) = std(subField);
        numStore(tInd,index) = sum(totLogic);
    end
end

% Plot
legLabels = {'Bulk','','Surface','','Interior'};
meanMat = medVals';
numMat = numStore';
timeVec = selTimes*deltaT;
figure
filtMatLogic = numMat > 100;
filtMat = meanMat; filtMat(~filtMatLogic) = NaN;
plot(timeVec,filtMat','LineWidth',2)
xlabel('Time (min)')
ylabel('Average Alignment')
% legend(legLabels{1:2:end})
set(gca,'FontSize',15)
box on
ylim([-0.5 1])
xlim([0 max(timeVec)])
xticks([0 17 35])
yticks([-0.5 0 1])
title(titleStr)
colororder(colorMat)

figure
plot(timeVec,(numMat./sum(numMat))','LineWidth',2)
xlabel('Time (min)')
ylabel('Number of Filaments')
% legend(legLabels{1:2:6})
set(gca,'FontSize',15)
colororder(colorMat)
ylim([0 1.1])
xlim([0 max(timeVec)])
xticks([0 17 35])
yticks([0 1])
% colorMat = [[100,0,100]; [150, 0, 150]; [230, 30, 165]; [1,210,105]; [0 180 100] ;[0 150 100]]/255; % watermelon

% Iterate through times histogram
totInds = 3;
stringCell = {'Bulk','Surface','Interior'};
rVals = [85 170 255];
rescaleY = 1;   yBnds = [0 .1];

figure
for currInd = 1:totInds
    currTitleStr = sprintf('2D Angle Separation - %s',stringCell{currInd});
    rVal = rVals(currInd);
    
    selField =  bndmod(acos(fDg2D),-pi/2,pi/2) ;
    binSpc = .1;
    binVals = (0:binSpc:(pi-binSpc))-pi/2;
    histTs = 1:3:40;
    % selLogic = lenLogic & volLogic & arLogic & psfLogic;
    % selField = order2D;
    % binVals = -.98:.04:.98;
    % Instantiate storage objects
    uniqueRs = unique(fData.(rField));
    
    colorTs = histTs;
    colorLen = max(histTs) + 1;   colorOffSet = 4;
    timeColorArray = othercolor('BuPu3',colorLen+colorOffSet);
    timeColorArray = timeColorArray((colorOffSet-1):end,:);
    
    % Isolate times
    subplot(totInds,1,currInd)
    % figure
    for tInd = 1:numel(histTs)
        currT = histTs(tInd);
        tLogic = fData.("Frame") == currT;
        % Isolate r bins
        rLogic = fData.(rField) == rVal;
        totLogic = tLogic & rLogic & selLogic;
        % Get order params
        subField = selField(totLogic);
        % [a,b] = histcounts(subField);
        [a,b] = histcounts(subField,binVals);
        if rescaleY == 1
            a = a/sum(a);   a(a==0) = NaN;
        end
        plot(b(2:end),a,'LineWidth',2);
        hold on
      
    end
    
    colororder(timeColorArray(colorTs,:))
    title(currTitleStr)
    xlabel('Average Order Parameter')
    ylabel('Count Fraction')
    xlim([(binVals(2)) max(binVals)])
    ylim(yBnds);
    
    mapTs = sort(colorTs);
    cbh = colorbar;
    colormap(timeColorArray(mapTs,:));
    cbh.Ticks = sort((mapTs - min(mapTs))/(max(mapTs)- min(mapTs))) ; %Create 8 ticks from zero to 1
    tickCell = cell(numel(mapTs),1);   
    [tickCell{[1 end]}] = deal(mapTs(1)*deltaT,mapTs(end)*deltaT);
    cbh.TickLabels = tickCell;  
end

%% 3D order parameter, counts, and histograms
selLogic = lenLogic & volLogic & arLogic;
selField = order3D;
titleStr = '3D Order - Filtered';
% Instantiate storage objects
uniqueRs = unique(fData.(rField));
meanVals = zeros(numel(selTimes),numel(uniqueRs));
stdVals = meanVals; medVals = meanVals; numStore = meanVals;

% Isolate times
for tInd = 1:numel(selTimes)
    currT = selTimes(tInd);
    tLogic = fData.("Frame") == currT;
    % Isolate r bins
    for index = 1:numel(uniqueRs)
        currR = uniqueRs(index);
        rLogic = fData.(rField) == currR;
        % Concatenate logic
        totLogic = tLogic & rLogic & selLogic;
        % Get order params
        subField = selField(totLogic);
        % Store 
        meanVals(tInd,index) = mean(subField);
        medVals(tInd,index) = median(subField);
        stdVals(tInd,index) = std(subField);
        numStore(tInd,index) = sum(totLogic);
    end
end

% Plot
legLabels = {'Bulk','','Surface','','Interior'};
meanMat = medVals';
numMat = numStore';
timeVec = selTimes*deltaT;
figure
filtMatLogic = numMat > 100;
filtMat = meanMat; filtMat(~filtMatLogic) = NaN;
plot(timeVec,filtMat','LineWidth',2)
xlabel('Time (min)')
ylabel('Average Alignment')
legend(legLabels{1:2:end})
set(gca,'FontSize',15)
box on
% ylim([0 1])
xlim([min(timeVec) max(timeVec)])
title(titleStr)
colororder(colorMat)

figure
plot(timeVec,numMat','LineWidth',2)
xlabel('Time (min)')
ylabel('Number of Filaments')
legend(legLabels{1:2:6})
set(gca,'FontSize',15)
colororder(colorMat)
% colorMat = [[100,0,100]; [150, 0, 150]; [230, 30, 165]; [1,210,105]; [0 180 100] ;[0 150 100]]/255; % watermelon


% Histograms
totInds = 3;
stringCell = {'Bulk','Surface','Interior'};
rVals = [85 170 255];
rescaleY = 1;   yBnds = [0 .1];
figure
for currInd = 1:totInds
    currTitleStr = sprintf('3D Angle Separation - %s',stringCell{currInd});
    rVal = rVals(currInd);
    
    selField =  bndmod(acos(fDg2D),-pi/2,pi/2) ;
    binSpc = .1;
    binVals = (0:binSpc:(pi-binSpc))-pi/2;
    histTs = 1:3:40;
    % selLogic = lenLogic & volLogic & arLogic & psfLogic;
    % selField = order2D;
    % binVals = -.98:.04:.98;
    % Instantiate storage objects
    uniqueRs = unique(fData.(rField));
    
    colorTs = histTs;
    colorLen = max(histTs) + 1;   colorOffSet = 4;
    timeColorArray = othercolor('BuPu3',colorLen+colorOffSet);
    timeColorArray = timeColorArray((colorOffSet-1):end,:);
    
    % Isolate times
    subplot(1,totInds,currInd)
    for tInd = 1:numel(histTs)
        currT = histTs(tInd);
        tLogic = fData.("Frame") == currT;
        % Isolate r bins
        rLogic = fData.(rField) == rVal;
        totLogic = tLogic & rLogic & selLogic;
        % Get order params
        subField = selField(totLogic);
        % [a,b] = histcounts(subField);
        [a,b] = histcounts(subField,binVals);
        if rescaleY == 1
            a = a/sum(a);   a(a==0) = NaN;
        end
        plot(b(2:end),a,'LineWidth',2);
        hold on
      
    end
    
    colororder(timeColorArray(colorTs,:))
    title(currTitleStr)
    xlabel('Average Order Parameter')
    ylabel('Count Fraction')
    xlim([(binVals(2)) max(binVals)])
    ylim(yBnds);
    
    mapTs = sort(colorTs);
    cbh = colorbar;
    colormap(timeColorArray(mapTs,:));
    cbh.Ticks = sort((mapTs - min(mapTs))/(max(mapTs)- min(mapTs))) ; %Create 8 ticks from zero to 1
    tickCell = cell(numel(mapTs),1);   
    [tickCell{[1 end]}] = deal(mapTs(1)*deltaT,mapTs(end)*deltaT);
    cbh.TickLabels = tickCell;  
end
