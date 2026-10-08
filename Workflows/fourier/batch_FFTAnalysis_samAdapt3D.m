% Power spectra from code Sam Wilkins sent
% 2024-08-13
% Modified for 3D 2026-01-08

%% Load
% dataDir =  'Session 81, Exp 2';
% dataName = 'Time%06i_raw560.tif';
% baseDirs = {'<redacted original absolute path>',...
baseDirs = {'Session 88, Exp 1',...
    % '<redacted original absolute path>',...
    'Session 88, Exp 2',...
    % '<redacted original absolute path>',...
    'Session 88, Exp 3',...
    % '<redacted original absolute path>',...
    'Session 88, Exp 5',...
    % '<redacted original absolute path>'};
    'Session 88, Exp 4'};

for dirInd = 1:numel(baseDirs)
% Set data name variables
dataDir =  fullfile(baseDirs{dirInd},'3 Illumination Bleach Corrected 16bit');
dataName = 't%03i_illBleachCorr16bit_560.tif';
saveDir = fullfile(baseDirs{dirInd},'5 FFT Analysis');
selectTimes = 1:40;
voxSize = [11*2/40 11*2/40 0.7];
numRings = 600;
invertC = 0;
% normT1 = 1;         % Normalize by T1 in fourier space?
rescaleFact = max(voxSize)./voxSize;
% rescaleFact = [1 1 1];
bool2D = 1;
selZ = unique(round(rescaleFact(3)*[4:3:90]));

% Instantiate storage, then store radially average power spectra
storeMat = zeros(numRings,numel(selectTimes));
if bool2D == 1
    storeMat = repmat(storeMat,[1 1 numel(selZ)]);
end
% shiftedMat = storeMat;
% Calculate power spectra for each time point
for tInd = 1:numel(selectTimes)
    % Load times
    currT = selectTimes(tInd);
    currTif = double(tiffreadVolume(fullfile(dataDir,sprintf(dataName,currT))));
    if prod(rescaleFact) == 1
        selImg = currTif;
    else
        selImg = imresize3(currTif,size(currTif)./rescaleFact);
    end
    if bool2D == 1
        selImg2D = selImg(:,:,selZ);
    end

    tic
    % Define converted wavenumbers and matrix for radial averaging
    if tInd == 1
        scVoxSize = rescaleFact.*voxSize;
        imgDims = size(selImg);
        if numel(imgDims) == 2
            imgDims(3) = 1;
        end
    % Generate weights for Hanning window - units of indices
        if bool2D == 1
            weights2D = generateNDHann(imgDims(1:2));
            weights = repmat(weights2D,[1 1 numel(selZ)]);
        else
            weights = generateNDHann(imgDims);
        end
    % Generate matrix of k values - units of length (microns)
        % image dimension in units of indices determines vector lengths
        k1 = genScaledKVec(imgDims(1),scVoxSize(1))';   %transpose
        k2 = genScaledKVec(imgDims(2),scVoxSize(2));
        k3 = permute(genScaledKVec(imgDims(3),scVoxSize(3)),[3 1 2]);
        % voxel dimensions rescale k-spacing in each dimension
        if bool2D == 1
            k = sqrt(k1.^2 + k2.^2);
        else
            k = sqrt(k1.^2 + k2.^2 + k3.^2);
        end
        [counts,kEdges,rings] = histcounts(k,numRings);
        % if bool2D == 1
        %     rings = repmat(rings,[1 1 numel(selZ)]);
        % end
    end

    % Calculate 3D power spectra - fftn on image
    % image dimensions and voxel spacings need not be identical
    for currZ = 1:size(storeMat,3)
        if bool2D == 1
            weightedImg = selImg2D(:,:,currZ).*weights2D;
        else
            weightedImg = selImg.*weights;
        end
        % Calculate the power spectrum
        fftImg = fftshift(fftn(weightedImg));
        if tInd == 1
            % Define vecotr of k-values for plotting
            scaledK = kEdges;    
            % powerSpec1 = powerSpec;
            fftImg1 = fftImg;
        end
        if currZ == 1
            powerSpec = (abs(fftImg).^2)./numel(weightedImg);
        elseif currZ > 1
            powerSpec(:,:,currZ) = (abs(fftImg).^2)./numel(weightedImg);
        end
        % Radially average and store
        for ringInd = 1:numRings
            if bool2D == 0
                storeMat(ringInd,tInd,currZ) = sum(powerSpec(rings == ringInd))/max(1,counts(ringInd));
            elseif bool2D == 1
                [currR,currC] = ind2sub(size(rings),find(rings == ringInd));
                inds3D = sub2ind(size(powerSpec),currR, currC, repmat(currZ,[numel(currC),1]));
                storeMat(ringInd,tInd,currZ) = sum(powerSpec(inds3D))/max(1,counts(ringInd));
            end
        end
    end
    % % Radially average and store
    % for ringInd = 1:numRings
    %     storeMat(ringInd,tInd,:) = sum(powerSpec(rings == ringInd))/max(1,counts(ringInd));
    % end
    toc
    pause(.01)
end

% save
if ~exist(saveDir,'dir')
    mkdir(saveDir)
end
save(fullfile(saveDir,sprintf('%03ibin_structFactor2D_variables_600bin.mat',numRings)),"selectTimes",'scVoxSize',"voxSize","scaledK","numRings","storeMat",'selZ');

end
%% Save
% save(fullfile(saveDir,sprintf('%03ibin_powerSpectra_variables.mat',numRings)),"selectTimes","pixSize","scaledK","numRings","selZ","timeColorArray","storeMat","shiftedMat");

%% Load

% saveDir = '';
% saveDir = '<redacted original absolute path>';
saveDir = 'Session 84';

load(fullfile(saveDir,'powerSpectra_variables.mat'))
% load(fullfile(saveDir,'600bin_powerSpectra_variables.mat'))

%% Plot things with transparency
% Select times for full color + transpacrency
deltaT = 0.5;
movkern = 6;
selectTimes = 0:24;
spacerLen = 0;
alphaTimes = [];
alphaVal = 0.2;
xmin = 1/124;
% Display boundaries
% xBnds = [4*10^(-3) .4];
% yBnds = [10^4 10^10];
xBnds = [2.4*10^(-3) .5];
yBnds = [10^3 5*10^7];
% Define boundaries for recolor
colorTimeBnds = 1:max(selectTimes);    
% colorTimeBnds = 1:4:24;    
colorStr = 'BuPu3';
colorOffSet = 25;
% Display strings
titleTag = 'Power Spectra Over Time';
xtitle = 'q (1/um)';
ytitle = 'Mean FFT Profile';

% Prepare colormap 
colorLen = max(colorTimeBnds) - min(colorTimeBnds) + 1;
colorTimeBnds = fliplr(colorTimeBnds);  
% fracCutOff = 0.0003;
% specialT = timeColorStamps(timeColorStamps <= max(colorTimeBnds));
% Reset color vector, if wanted
timeColorArray = othercolor(colorStr,colorLen+colorOffSet);
timeColorArray = timeColorArray((colorOffSet-1):end,:);
% Prepare alpha frames
tcaAlpha = [timeColorArray, .8*ones(size(timeColorArray,1),1)];
tcaAlpha(alphaTimes,4) = alphaVal;

% Space lines, if requested
if spacerLen > 0
    spacerVec = spacerLen.^selectTimes;
    yBnds(end) = yBnds(end)*spacerVec(end);
else
    spacerVec = ones(numel(selectTimes),1);
end

% Approximate peaks
xCut = find(scaledK > xmin, 1);
% test = mean(storeMat,3);    ogMat = storeMat;
% storeMat = test;
avged  = movmean(squeeze(storeMat(xCut:end,selectTimes)),movkern);
% [maxVals,maxInds] = max(avged);

% Plot
figure
for tInd = 1:numel(selectTimes)
    currT = selectTimes(tInd);
    currField = mean(squeeze(storeMat(:,selectTimes(tInd))),2);
    % plot(scaledK(1:end-1), currField*spacerVec(tInd),'LineWidth',2,'Color',tcaAlpha((tInd),:));
    % plot(scaledK(1:end-1), currField*spacerVec(tInd),'LineWidth',2,'Color',tcaAlpha(selectTimes(tInd),:));
    scatter(scaledK(xCut:end-1), squeeze(storeMat(xCut:end,currT))*spacerVec(tInd),16,'filled','MarkerFaceColor',tcaAlpha(currT,1:3));
    hold on
    % plot(scaledK(xCut:end-1), squeeze(storeMat(xCut:end,currZ,currT))*spacerVec(tInd),'LineWidth',1,'Color',timeColorArray(currT,:));
    plot(scaledK(xCut:end-1), avged(:,tInd)*spacerVec(tInd),'LineWidth',1,'Color','black');
   
end
xlabel(xtitle)
ylabel(ytitle)
title(titleTag)
set(gca,'FontSize',15)
xlim(xBnds)
ylim(yBnds)
cbh = colorbar;
colormap(timeColorArray(selectTimes,:));
cbh.Ticks = ([min(selectTimes) max(selectTimes)] - min(selectTimes))/(max(selectTimes)- min(selectTimes)) ; %Create 8 ticks from zero to 1
% cbh.Ticks = (selectTimes - min(selectTimes))/(max(selectTimes)- min(selectTimes)) ; %Create 8 ticks from zero to 1
cbh.TickLabels = num2cell(([min(selectTimes) max(selectTimes)]-1)*deltaT) ; 
set(gca,'XScale','log','YScale','log');
box on

%% Plot spectra, movemean, and reference slope
% Select times for full color + transpacrency
deltaT = 0.5;
currZ = 20;
selectTimes = 1:10;
spacerLen = 0;
alphaTimes = [];
alphaVal = 0.2;
xmin = 1/150;
movkern = 5;
% Display boundaries
xBnds = [2*10^(-3) .4];
yBnds = [10^4.2 10^9];
% Define boundaries for recolor
colorTimeBnds = (min(selectTimes)-1):(max(selectTimes) + 2);    
% colorTimeBnds = 1:4:24;    
colorStr = 'BuPu3';
colorOffSet = 4;
% Display strings
titleTag = '';
% titleTag = 'Power Spectra Over Time';
xtitle = 'q (1/um)';
ytitle = 'Mean FFT Profile';

% Prepare colormap 
colorLen = max(colorTimeBnds) - min(colorTimeBnds) + 1;
colorTimeBnds = fliplr(colorTimeBnds);  
% Reset color vector, if wanted
timeColorArray = othercolor(colorStr,colorLen+colorOffSet);
timeColorArray = timeColorArray((colorOffSet-1):end,:);

% Space lines, if requested
if spacerLen > 0
    spacerVec = spacerLen.^selectTimes;
    yBnds(end) = yBnds(end)*spacerVec(end);
else
    spacerVec = ones(numel(selectTimes),1);
end

% Approximate peaks
xCut = find(scaledK > xmin, 1);
avged  = movmean(squeeze(storeMat(xCut:end,selectTimes,currZ)),movkern);
[maxVals,maxInds] = max(avged);
% Plot
figure
pksVec  = [];
for tInd = 1:numel(selectTimes)
    currT = selectTimes(tInd);
    % Movemean average
    % plot(scaledK(xCut:end-1), movmean(squeeze(storeMat(xCut:end,currZ,selectTimes(tInd)))*spacerVec(tInd),10),'LineWidth',2,'Color','black','LineStyle','--');
    hold on
    % data points
    scatter(scaledK(xCut:end-1), squeeze(storeMat(xCut:end,currT,currZ))*spacerVec(tInd),10,'filled','MarkerFaceColor',timeColorArray(currT,:));
    % scatter(scaledK(xCut:end-1), squeeze(storeMat(xCut:end,currT))*spacerVec(tInd),16,'filled','MarkerFaceColor',timeColorArray(currT,:),'MarkerEdgeColor','black');
    % plot(scaledK(xCut:end-1), squeeze(storeMat(xCut:end,currT))*spacerVec(tInd),'LineWidth',1,'Color',timeColorArray(currT,:));
    % plot(scaledK(xCut:end-1), avged(:,tInd)*spacerVec(tInd),'LineWidth',1,'Color','black');
    % plot(scaledK(xCut:end-1), avged(:,tInd)*spacerVec(tInd),'LineWidth',1,'Color','black','LineStyle','--');
    if tInd ~= 1
        scatter(scaledK(maxInds(tInd) + round((movkern)/2) +2), maxVals(tInd)*spacerVec(tInd),60,'filled',...
            'MarkerFaceColor',[230 160 40]/255,'MarkerEdgeColor','black','Marker','^');
    end
    pksVec(1:2,end+1) = [scaledK(maxInds(tInd) + round(movkern/2)+2) maxVals(tInd)];
end
xlabel(xtitle)
ylabel(ytitle)
title(titleTag)
set(gca,'FontSize',15)
xlim(xBnds)
ylim(yBnds)
cbh = colorbar;
colormap(timeColorArray(selectTimes,:));
cbh.Ticks = ([min(selectTimes) max(selectTimes)] - min(selectTimes))/(max(selectTimes)- min(selectTimes)) ; %Create 8 ticks from zero to 1
cbh.TickLabels = num2cell(([min(selectTimes) max(selectTimes)]-1)*deltaT) ; 
set(gca,'XScale','log','YScale','log');

% Add slope of slopeFit for reference
slopeFit = -3.8;
selT = selectTimes(end);
xRange = [.04 .2];      xShft = 10^.1;
[~,kInd1] = min(abs(scaledK(1:end-1) - xRange(1)));
[~,kInd2] = min(abs(scaledK(1:end-1) - xRange(2)));
xCrds = scaledK([kInd1 kInd2])*xShft;
% ycrd1 = storeMat(kInd1+1,currZ,selT);
% ycrd2 = storeMat(kInd2 + 1,currZ,selT);
% yCrd2Slope = ycrd1*exp(slopeFit*diff(log(xCrds)));
plot(xCrds', [ycrd1 yCrd2Slope]','LineWidth',2,'Color','black')
box on
 

%% Plot spectra, movemean, and reference slope

% Select times for full color + transpacrency
deltaT = 0.5;
currZ = 2:4:29;
selectTimes = 1:10;
spacerLen = 0;
alphaTimes = [];
alphaVal = 0.2;
xmin = 1/150;
movkern = 5;
% Display boundaries
xBnds = [2*10^(-3) .4];
yBnds = [10^4.2 10^9];
% Define boundaries for recolor
colorTimeBnds = (min(selectTimes)-1):(max(selectTimes) + 2);    
% colorTimeBnds = 1:4:24;    
colorStr = 'BuPu3';
colorOffSet = 10;
% Display strings
titleTag = '';
% titleTag = 'Power Spectra Over Time';
xtitle = 'q (1/um)';
ytitle = 'Mean FFT Profile';

% Prepare colormap 
colorLen = max(colorTimeBnds) - min(colorTimeBnds) + 1;
colorTimeBnds = fliplr(colorTimeBnds);  
% Reset color vector, if wanted
timeColorArray = othercolor(colorStr,colorLen+colorOffSet);
timeColorArray = timeColorArray((colorOffSet-1):end,:);

% Space lines, if requested
if spacerLen > 0
    spacerVec = spacerLen.^selectTimes;
    yBnds(end) = yBnds(end)*spacerVec(end);
else
    spacerVec = ones(numel(selectTimes),1);
end

% Approximate peaks
xCut = find(scaledK > xmin, 1);
currData = storeMat(xCut:end,currZ,selectTimes);
avged  = movmean(mean(currData,2),movkern);
[maxVals,maxInds] = max(avged);
% Plot
figure
pksVec  = [];
for tInd = 1:numel(selectTimes)
    currT = selectTimes(tInd);
    % Movemean average
    % plot(scaledK(xCut:end-1), movmean(squeeze(storeMat(xCut:end,currZ,selectTimes(tInd)))*spacerVec(tInd),10),'LineWidth',2,'Color','black','LineStyle','--');
    hold on
    % data points
    scatter(scaledK(xCut:end-1), squeeze(mean(currData,2))*spacerVec(tInd),10,'filled','MarkerFaceColor',timeColorArray(currT,:));
    % scatter(scaledK(xCut:end-1), squeeze(storeMat(xCut:end,currT))*spacerVec(tInd),16,'filled','MarkerFaceColor',timeColorArray(currT,:),'MarkerEdgeColor','black');
    % plot(scaledK(xCut:end-1), squeeze(storeMat(xCut:end,currT))*spacerVec(tInd),'LineWidth',1,'Color',timeColorArray(currT,:));
    % plot(scaledK(xCut:end-1), avged(:,tInd)*spacerVec(tInd),'LineWidth',1,'Color','black');
    % plot(scaledK(xCut:end-1), avged(:,tInd)*spacerVec(tInd),'LineWidth',1,'Color','black','LineStyle','--');
    if tInd ~= 1
        scatter(scaledK(maxInds(tInd) + round((movkern)/2) +2), maxVals(tInd)*spacerVec(tInd),60,'filled',...
            'MarkerFaceColor',[230 160 40]/255,'MarkerEdgeColor','black','Marker','^');
    end
    pksVec(1:2,end+1) = [scaledK(maxInds(tInd) + round(movkern/2)+2) maxVals(tInd)];
end
xlabel(xtitle)
ylabel(ytitle)
title(titleTag)
set(gca,'FontSize',15)
xlim(xBnds)
ylim(yBnds)
cbh = colorbar;
colormap(timeColorArray(selectTimes,:));
cbh.Ticks = ([min(selectTimes) max(selectTimes)] - min(selectTimes))/(max(selectTimes)- min(selectTimes)) ; %Create 8 ticks from zero to 1
cbh.TickLabels = num2cell(([min(selectTimes) max(selectTimes)]-1)*deltaT) ; 
set(gca,'XScale','log','YScale','log');

% Add slope of slopeFit for reference
slopeFit = -3.8;
selT = selectTimes(end);
xRange = [.04 .2];      xShft = 10^.1;
[~,kInd1] = min(abs(scaledK(1:end-1) - xRange(1)));
[~,kInd2] = min(abs(scaledK(1:end-1) - xRange(2)));
xCrds = scaledK([kInd1 kInd2])*xShft;
ycrd1 = mean(storeMat(kInd1+1,currZ,selT),2);
% ycrd2 = storeMat(kInd2 + 1,currZ,selT);
yCrd2Slope = ycrd1*exp(slopeFit*diff(log(xCrds)));
plot(xCrds', [ycrd1 yCrd2Slope]','LineWidth',2,'Color','black')
box on
 
%% Plot spectra from two directories
% saveDir1 = '<redacted original absolute path>';
saveDir1 = 'Session 81, Exp 2';
saveDir2 = saveDir1;
saveName1 = '500bin_powerSpectra_variables.mat';
saveName2 = 'RescaleImgs_500bin_powerSpectra_variables.mat';
% Select times for full color + transpacrency
deltaT = 0.5;
selectTimes = 1:6;
spacerLen = 0;
alphaTimes = [];
alphaVal = 0.2;
xmin = 1/400;
movkern = 5;
% Display boundaries
xBnds = [2*10^(-3) .4];
yBnds = [10^4.2 10^9];
% Define boundaries for recolor
colorTimeBnds = (min(selectTimes)-1):(max(selectTimes) + 2);    
% colorTimeBnds = 1:4:24;    
colorStr = 'BuPu3';
colorOffSet = 10;
% Display strings
titleTag = '';
% titleTag = 'Power Spectra Over Time';
xtitle = 'q (1/um)';
ytitle = 'Mean FFT Profile';

% Prepare colormap 
colorLen = max(colorTimeBnds) - min(colorTimeBnds) + 1;
colorTimeBnds = fliplr(colorTimeBnds);  
% Reset color vector, if wanted
timeColorArray = othercolor(colorStr,colorLen+colorOffSet);
timeColorArray = timeColorArray((colorOffSet-1):end,:);

% Load data sets
load(fullfile(saveDir1,saveName1));
storeMat1 = storeMat;   scaledK1 = scaledK;
load(fullfile(saveDir2,saveName2));
storeMat2 = storeMat;   scaledK2 = scaledK;

% Space lines, if requested
if spacerLen > 0
    spacerVec = spacerLen.^selectTimes;
    yBnds(end) = yBnds(end)*spacerVec(end);
else
    spacerVec = ones(numel(selectTimes),1);
end

% Approximate peaks
xCut1 = find(scaledK1 > xmin, 1);
xCut2 = find(scaledK2 > xmin, 1);
% Plot
figure
for tInd = 1:numel(selectTimes)
    currT = selectTimes(tInd);
    % Movemean average
    hold on
    % data points 1
    scatter(scaledK1(xCut:end-1), squeeze(storeMat1(xCut:end,currT))*spacerVec(tInd),32,'filled','MarkerFaceColor',timeColorArray(currT,:),'MarkerEdgeColor','black');
    % data points 2
    scatter(scaledK2(xCut:end-1), squeeze(storeMat2(xCut:end,currT))*spacerVec(tInd),16,'filled','MarkerFaceColor',timeColorArray(currT,:));

end
xlabel(xtitle)
ylabel(ytitle)
title(titleTag)
set(gca,'FontSize',15)
xlim(xBnds)
ylim(yBnds)
cbh = colorbar;
colormap(timeColorArray(selectTimes,:));
cbh.Ticks = ([min(selectTimes) max(selectTimes)] - min(selectTimes))/(max(selectTimes)- min(selectTimes)) ; %Create 8 ticks from zero to 1
cbh.TickLabels = num2cell(([min(selectTimes) max(selectTimes)]-1)*deltaT) ; 
set(gca,'XScale','log','YScale','log');

box on
%% Overlay movemean in loglog
% Plot
% figure
xCut = find(scaledK > xmin, 1);
for tInd = 1:numel(selectTimes)
    hold on
end

%% Overlay fit(s)
selRange = 5:600;
loglog(scaledK(selRange),2.87*10^8*(1./(1+(scaledK(selRange)*36.66).^3.5)*spacerVec(end)),'--','Color','black','LineWidth',3)

%% Plot pkvecs over time
movkern = 5;
selectTimes = 1:18;
subTimes = 8:2:16;
tInds = ismember(selectTimes,subTimes);
avged  = movmean(squeeze(storeMat(xCut:end,currZ,selectTimes)),movkern);
[maxVals,maxInds] = max(avged);

pksVec = [];
for tInd = 1:numel(selectTimes)
    pksVec(1:2,end+1) = [scaledK(maxInds(tInd) + round(movkern/2)+2) maxVals(tInd)];
end
figure
scatter(selectTimes*deltaT,1./pksVec(1,:),30,'black','filled');
hold on
scatter(subTimes*deltaT,1./pksVec(1,tInds),60,'filled',...
        'MarkerFaceColor',[230 160 40]/255,'MarkerEdgeColor','black','Marker','^');
box on
xlabel('Time (mins)')
ylabel('q_{pk}^{-1}(\mum)')
xlim([0 10])
ylim([25 45])
yticks([30 40])
xticks([0 5 10])


%% Plot with overlapped black line movemean averages
% timeColorVec = [1 0 0; 1 0 0; 0 0 1; 0 1 0; 0 0 0; 0 0 0];
% timeColorVec = [ 54 186 152; 233 196 106; 244 162 97; 231 111 81;  0 0 0; 0 0 0]/255; 
timeColorVec = [ 233 196 106; 244 162 97; 231 111 81; 24 12 30; 18 6 24; 0 0 0]/255;   %*
% timeColorVec = [ 233 196 106; 54 186 152; 231 111 81; 0 0 0; 0 0 0; 0 0 0]/255; %*
% timeColorVec = [ 233 196 106; 54 186 152; 244 162 97; 244 162 97; 0 0 0; 0 0 0]/255;
timeColorStamps = [30 330 660 2100 3000 3000]/30;     % Session 84 exp 1
% timeColorStamps = [30 30 360 1140 2100 3000]/30;     % Session 84 exp 1
timeColorArray = stitchGradients(timeColorVec,timeColorStamps);

selectTimes = fliplr([1 5 7 9 11 13 15 21]);
% selectTimes = fliplr([1:16 17:2:28]);
figure
currZ = 1;
selInds = 5:600;
% loglog(scaledK(4:end-1), movmean(squeeze(storeMat(4:end,currZ,selectTimes)),5),'LineWidth',1);
loglog(scaledK(selInds), squeeze(storeMat(selInds,currZ,selectTimes)),'LineWidth',1);
hold on
% scatter(scaledK(1:end-1), squeeze(storeMat(:,currZ,selectTimes)),15,'filled');
scatter(scaledK(selInds), squeeze(storeMat(selInds,currZ,selectTimes)),7,'filled');
% loglog(scaledK(1:end-1), squeeze(storeMat(:,currZ,selectTimes)),'LineWidth',2);
% loglog(scaledK(1:end-1), squeeze(shiftedMat(:,currZ,selectTimes)),'LineWidth',2);
% loglog(scaledK(1:end-1), squeeze(storeMat(:,currZ,selectTimes)./storeMat(:,currZ,1)),'LineWidth',2);
colororder(timeColorArray(selectTimes,:));
% colororder(pink)
xlabel('q (1/um)')
ylabel('Mean FFT Profile')
title('Power Spectra Over Time')
set(gca,'FontSize',15)
% ylim([10^4 10^11])
xlim([4*10^(-3) .4])
% xlim([5*10^(-3) .5])
cbh = colorbar;
colorTimes = sort(selectTimes);
% colormap(timeColorArray(colorTimes,:));
colormap('pink')
cbh.Ticks = (colorTimes - min(colorTimes))/(max(colorTimes)- min(colorTimes)) ; %Create 8 ticks from zero to 1
cbh.TickLabels = num2cell(colorTimes*30) ; 
set(gca,'XScale','log','YScale','log');
loglog(scaledK(1:end-1), movmean(squeeze(storeMat(1:end,currZ,selectTimes)),5),'LineWidth',2,'LineStyle','--','Color',[.1 .18 .1]);
alpha(0.5)

%% 
% %% 
% 
% k=sqrt(bsxfun(@plus,k1.^2,k2.^2));
% [k,ind]=sort(k(:));
% numbin=round([1:.5:floor(size(k,1).^(1/2))].^2);
% startbin=numbin(1:end-1);
% endbin=numbin(2:end)-1;
% 
% Sq1=abs(fftshift(fft2(u)).^2)./numel(selImgSlices(:,:,1));
% Sq1(floor(size(Sq1,1)/2)+1,floor(size(Sq1,2)/2)+1)=0;
% % Sq11=Sq1(:,:);
% sSq=Sq1(ind);
% Sqbin_dummy2=zeros(numel(startbin),1);
% numbin2=zeros(numel(startbin),1);
% kmag=zeros(numel(startbin),1);
% for q=1:numel(numbin)-1
%     totbins=startbin(q):endbin(q);
%     numbin2(q)=sum(~isnan(sSq(startbin(q):endbin(q))));
%     kmag(q)=sum(k(startbin(q):endbin(q))./numbin2(q),'omitnan');
%     kvar(q)=std(k(startbin(q):endbin(q)))./sqrt(numbin(q));
%     Sqbin_dummy2(q)=sum(sSq(startbin(q):endbin(q))./numbin2(q),'omitnan');
%     Sqbinerr(q)=std(sSq(startbin(q):endbin(q)))./sqrt(numbin(q));
% end
% % toc
% Sq_binimg=Sqbin_dummy2(1:end);
% ktotimg=kmag(1:end)./(2.*pi*pixSize);
% loglog(ktotimg,Sq_binimg);
% % pause(.1)
% hold on
% end