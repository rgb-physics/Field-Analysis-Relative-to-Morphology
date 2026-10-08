%% Calc mean order parameter from rp3D in binned domains
% rName contains tif with deltaR bin encoded at each index; can be distance
% transform or in out on matrix
% 2025-02-16 - Rémi Boros

% filDataDir = '<redacted original absolute path>';
filDataDir = 'Session 88, Exp 4';
filDataName = 'Filament Statistics %03i.mat';
% rDir = '<redacted original absolute path>';
rDir = 'Session 88, Exp 4';
rName = 'Time%06i_3ChanSegs.tif';

ccField = 'rp3D';
rField = 'rAtCens';
selTimes = 1:70;
rBins = [-Inf 100 220 Inf];     % Units are whatever rFiles are stored in
cutLen = 2; cutVol = 4; cutAR = 1.5;
cutZ = 0.4;

deltaT = 30/60;

colorMat = min(1,[[100,0,100];  [230, 30, 165];  [0 180 100] ]/255); % watermelon
dispBool = 0;

%% Load
allMeans3D = zeros(numel(selTimes),numel(rBins)-1);
allSTDs3D = allMeans3D;
allCounts3D = allMeans3D;
allMeans2D = allMeans3D;
allSTDs2D = allMeans3D;
allCounts2D = allMeans3D;
% Iterate over time
for tInd = 1:numel(selTimes)
% Load Data
    currT = selTimes(tInd);
    if tInd == 1
        load(fullfile(filDataDir,'FilamentDetect_metadata.mat'),'imgSize');
    end
    currCCs = load(fullfile(filDataDir,sprintf(filDataName,currT)),ccField).(ccField);
    load(fullfile(filDataDir,sprintf(filDataName,currT)),rField).(rField);
    rMat = double(tiffreadVolume(fullfile(rDir,sprintf(rName,currT))));
    
% Concatenate filament properties
    allCens = [currCCs.Centroid];   allDirecs = [currCCs.Directors];
    allLens = [currCCs.Lengths(:)]; allARs = [currCCs.AspectRatios(:)];
    allVols = [currCCs.Volume(:)];  allGrads = [currCCs.GradsAtCens];
    cenInds = [currCCs.CoMInds(:)];
    zAligns = allDirecs(:,3);
    
% Calculate order parameters
    gnDot = sum(allDirecs.*allGrads,2);
    order3D = min(1,max(-0.5,1/2*(3*gnDot.^2 - 1)));
    order2D = min(1,max(-1,(1/1*(2*gnDot.^2 - 1))));

    % Define Cross talk table
    xTalk = table();
    xTalk.('order3D') = order3D;
    xTalk.('order2D') = order2D;
    xTalk.('dotAlign') = gnDot;
    
% Generate Logic
    lenLogic = allLens > cutLen;    volLogic = allVols > cutVol;
    arLogic = allARs > cutAR;       
    % zLogic = ismember(zSlice, zRange);
    inplaneLogic = zAligns < cutZ;
    fullLogic = lenLogic & volLogic & arLogic;
    
% Sample deltaR at center indices
    if sum( imgSize == size(rMat) )/numel(imgSize) ~= 1
        rMat = imresize3(rMat,imgSize,'nearest');
    end
    rAtCens = rMat(cenInds);
    [~,~,rInds] = histcounts(rAtCens,rBins);

    %%% ASIDE TEST %%%
    selLogic = fullLogic;
    if dispBool == 1
        centersMat = zeros([imgSize 3]);
        testStrel = strel('sphere',3);
    end
    for index = 1:3
        currLogic = (rInds == index) & selLogic;
        % Store index of bin for corresponding centroids
        xTalk.('rBinInd')(find(currLogic)) = index;
        % Store means, etc.
        allMeans3D(tInd,index) = mean(order3D(currLogic));
        allSTDs3D(tInd,index) = std(order3D(currLogic));
        allCounts3D(tInd,index) = sum(currLogic);
        allMeans2D(tInd,index) = mean(order2D(currLogic & inplaneLogic));
        allSTDs2D(tInd,index) = std(order2D(currLogic & inplaneLogic));
        allCounts2D(tInd,index) = sum(currLogic & inplaneLogic);
        if dispBool == 1
            centersMat(:,:,:,index)  = imdilate(consMatLnB(ones(imgSize),cenInds(currLogic)),testStrel)*150;
        end
    end
    if dispBool == 1
        totComs = sum(centersMat,4);
        totBG = consMatLnB(rMat,~logical(totComs));
        finalMat = centersMat + repmat(totBG,1,1,1,3)/3;
        finalMat = uint8(finalMat);
        orthosliceViewer(finalMat);
        pause(1);
    end
    %%% ASIDE TEST END %%%

% Iterate through delta R bins
    % for currBin = 1:numel(unique(rInds))
    %     % Find centroids in current bin
    %     currInds = rInds == currBin;
    %     % Store index of bin for corresponding centroids
    %     xTalk.('rBinInd')(currInds) = currInds(currInds==1)*currBin;
    %     % Update logic
    %     patchLogic = fullLogic & currInds;
    %     % Store means, etc.
    %     allMeans3D(tInd,currBin) = mean(order3D(patchLogic));
    %     allSTDs3D(tInd,currBin) = std(order3D(patchLogic));
    %     allCounts3D(tInd,currBin) = sum(patchLogic);
    %     allMeans2D(tInd,currBin) = mean(order2D(patchLogic & inplaneLogic));
    %     allSTDs2D(tInd,currBin) = std(order2D(patchLogic & inplaneLogic));
    %     allCounts2D(tInd,currBin) = sum(patchLogic & inplaneLogic);
    % end
    save(fullfile(filDataDir,sprintf(filDataName,currT)),'xTalk','-append');
end
save(fullfile(filDataDir,'AlignStats.mat'),'allMeans3D','allSTDs3D','allCounts3D','allMeans2D','allSTDs2D','allCounts2D');

%% 
legLabels = {'Bulk','','Surface','','Interior'};
% meanMat = allMeans2D';
% stdMat = allSTDs2D';
% numMat = allCounts2D';
meanMat = allMeans3D';
stdMat = allSTDs3D';
numMat = allCounts3D';
timeVec = selTimes*deltaT;
figure
filtMatLogic = numMat > 100;
filtMat = meanMat; filtMat(~filtMatLogic) = NaN;
% plot(timeVec,filtMat','LineWidth',2)
for index = 1:size(meanMat,1)
    currColor = colorMat(index,:);
    % plotMeanStdPoly(filtMat(index,:),stdMat(index,:)./sqrt(numMat(index,:)),timeVec,currColor,0.4,'black');
    plotMeanStdPoly(filtMat(index,:),stdMat(index,:),timeVec,currColor,0.4,'black');
end
xlabel('Time (min)')
ylabel('Average Alignment')
legend(legLabels)
set(gca,'FontSize',15)
box on
% ylim([0 1])
xlim([0 20])
% colororder(colorMat)

figure
plot(timeVec,numMat','LineWidth',2)
xlabel('Time (min)')
ylabel('Number of Filaments')
legend(legLabels{1:2:6})
set(gca,'FontSize',15)
colororder(colorMat)
% colorMat = [[100,0,100]; [150, 0, 150]; [230, 30, 165]; [1,210,105]; [0 180 100] ;[0 150 100]]/255; % watermelon

%% Plot order parameter over time for different delta r bins
timeVec = timeRange*timeSpace;
meanMat = zeros(numel(rBin)-1,numel(timeVec));
numMat = meanMat;       stdMat = meanMat;
maskLogic = maskedFils == 0;


for tInd = 1:numel(timeRange)
        
    currT = timeRange(tInd);
    tLogic = objInds == currT;

    for rInd = 1:(numel(rBin) - 1)
        if binMode == 1
            rEdge1 = rBin(rInd);    rEdge2 = rBin(rInd+1);
            rLogic = (filDeltaRs >= rEdge1) & (filDeltaRs < rEdge2);
        elseif binMode == 0 
            currSeg = tiffreadVolume(fullfile(seg3ChanDir,sprintf(seg3Name,currT)));
            rescaleSeg = imresize3(currSeg,ogImgSize);
            
        end
        
        currLogic = generalFilt & tLogic & rLogic & maskLogic;
        % currAligns = allAligns(currLogic);
        currAligns = tensorAligns(currLogic);
        meanMat(rInd,tInd) = mean(currAligns);
        stdMat(rInd,tInd) = std(currAligns);
        numMat(rInd,tInd) = sum(currLogic);
    end
end

figure
filtMatLogic = numMat > 100;
filtMat = meanMat; filtMat(~filtMatLogic) = NaN;
% plot(timeVec,filtMat','LineWidth',2)
for index = 1:size(meanMat,1)
    currColor = colorMat(index,:);
    plotMeanStdPoly(filtMat(index,:),stdMat(index,:)./sqrt(numMat(index,:)),timeVec,currColor,0.4,'black');
    % plotMeanStdPoly(filtMat(index,:),stdMat(index,:)./numMat(index,:),timeVec,currColor,0.4,'black');
end
xlabel('Time (min)')
ylabel('Average Alignment')
legend(legLabels)
set(gca,'FontSize',15)
box on
% ylim([0 1])
xlim([0 20])
% colororder(colorMat)

figure
plot(timeVec,numMat','LineWidth',2)
xlabel('Time (min)')
ylabel('Number of Filaments')
legend(legLabels{1:2:6})
set(gca,'FontSize',15)
colororder(colorMat)

% %% Plot distribution of alignments over time
% subTimes = 1:5:50;
% for rInd = 1:(numel(rBin) - 1)
% 
%     rEdge1 = rBin(rInd);    rEdge2 = rBin(rInd+1);
%     rLogic = (filDeltaRs >= rEdge1) & (filDeltaRs < rEdge2);
% figure
%     for tInd = 1:numel(subTimes)
%         currT = subTimes(tInd);
%         tLogic = objInds == currT;
% 
%         currLogic = generalFilt & tLogic & rLogic & maskLogic;
%         % currAligns = allAligns(currLogic);
%         currAligns = tensorAligns(currLogic);
% % histogram(currAligns)
%     end
% end


