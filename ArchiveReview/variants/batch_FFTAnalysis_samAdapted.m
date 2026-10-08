% Power spectra from code Sam Wilkins sent
% 2024-08-13

%% Load
% dataDir =  '<redacted original absolute path>';
dataDir =  'Session 84';
dataName = 't%03i_illBleachCorr16bit_560.tif';
% saveDir = '<redacted original absolute path>';
saveDir = 'Session 84';
selectTimes = 1:40;
selZ = 5:10:79;
pixSize = 11*2/20;
numRings = 500;
invertC = 0;
% normT1 = 1;         % Normalize by T1 in fourier space?

% timeColorVec = [1 0 0; 1 0 0; 0 0 1; 0 1 0; 0 0 0; 0 0 0];
% timeColorStamps = [1 1 12 38 70 100];     % Session 84 exp 1
% timeColorArray = stitchGradients(timeColorVec,timeColorStamps);

%% Instantiate storage, then store radially average power spectra
storeMat = zeros(numRings,numel(selZ),numel(selectTimes));
shiftedMat = storeMat;
% Calculate power spectra for each time point
tic
for tInd = 1:numel(selectTimes)
    % Load times
    currT = selectTimes(tInd);
    currTif = double(tiffreadVolume(fullfile(dataDir,sprintf(dataName,currT))));
    selImgSlices = currTif(:,:,selZ);

    % Define converted wavenumbers and matrix for radial averaging
    if tInd == 1
        imgDims = size(selImgSlices);
        if numel(imgDims) == 2
            imgDims(3) = 1;
        end
        back = ones(imgDims(1:2));
        % tic
        [X,Y]=meshgrid(1:imgDims(2),1:imgDims(1));
        weights=.5.*(1 - cos(2*pi*X./imgDims(2))).*.5.*(1 - cos(2*pi*Y./imgDims(1)));   %Hanning window
        k1 = 2*pi*genScaledKVec(imgDims(1))';   %transpose
        k2 = 2*pi*genScaledKVec(imgDims(2));
        k = sqrt(k1.^2 + k2.^2);
        [counts,kEdges,rings] = histcounts(k,numRings);
    end
    % Iterate over each z slice, calculate and bin power spectrum
    for zInd = 1:imgDims(3)
    % zInd = 1;
        currSlice = selImgSlices(:,:,zInd);
        % weightedSlice = double(currSlice);
        weightedSlice = double(currSlice).*weights./back;
        % Calculate the power spectrum
        fftImg = fftshift(fft2(weightedSlice));
        if tInd == 1
            % powerSpec1 = powerSpec;
            fftImg1 = fftImg;
        end
        powerSpec = (abs(fftImg).^2)./numel(weightedSlice);
        % shiftedSpec = (abs(fftImg - fftImg1).^2)./numel(weightedSlice);
        % Bin based on radial k value using bin indices
        for ringInd = 1:numRings
            storeMat(ringInd,zInd,tInd) = sum(powerSpec(rings == ringInd))/max(1,counts(ringInd));
            % shiftedMat(ringInd,zInd,tInd) = sum(shiftedSpec(rings == ringInd))/max(1,counts(ringInd));
        end
    end

    if mod(tInd,10) == 1
        toc
        tic
    end

end
% Define vecotr of k-values for plotting
scaledK = kEdges/(2*pi*pixSize);
%% Save
save(fullfile(saveDir,'500bin_powerSpectra_variables.mat'),"selectTimes","pixSize","scaledK","numRings","selZ","timeColorArray","storeMat","shiftedMat");

%% Load

% saveDir = '';
% saveDir = '<redacted original absolute path>';
saveDir = 'Session 84';

% load(fullfile(saveDir,'powerSpectra_variables.mat'))
load(fullfile(saveDir,'500bin_powerSpectra_variables.mat'))

%% Plot things with transparency
% Select times for full color + transpacrency
tFlip = 25;             % index of T = 0, typically indicated by <max(rho)>
deltaT = 0.5;
% baseTimes = [1 5:13 15 17];
% zInd = 1:8;  
% colorStr = 'PuRd3';
% selectTimes = baseTimes(1:2:end);
zInd = 5;  
colorStr = 'BuPu3';
% selectTimes = baseTimes(2:2:end);
% selectTimes = [10 12];
selectTimes = [1 5:13 15 17];
alphaTimes = [];
alphaVal = 0.2;
xmin = 1/185;
movkern = 5;
% Display boundaries
% xBnds = [4*10^(-3) .4];
% yBnds = [10^4 10^10];
xBnds = [2.4*10^(-3) .35];
yBnds = [10^2 10^7];
% Define boundaries for recolor
colorTimeBnds = 1:max(selectTimes);    
% colorTimeBnds = 1:4:24;  
colorOffSet = 16;
% Display strings
titleTag = sprintf('Scattering - Z:%i',selZ(zInd));
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
selMat  = storeMat(xCut:end,zInd,selectTimes);
zAvgMat = squeeze(mean(selMat,2));
avged = movmean(zAvgMat,movkern);
% avged  = movmean(squeeze(storeMat(xCut:end,zInd,selectTimes)),movkern);
% [maxVals,maxInds] = max(avged);

% Plot
figure
    hold on
for tInd = 1:numel(selectTimes)
    currT = selectTimes(tInd);
    currK = scaledK(xCut:end-1);
    currField = zAvgMat(:,tInd);
    % plot(scaledK(xCut:end-1), avged(:,tInd)*spacerVec(tInd),'LineWidth',.5,'Color',[.1 .1 .1]);
   
    % if mod(tInd,2) == 1
        scatter(currK, currField*spacerVec(tInd),10,'filled','MarkerFaceColor',tcaAlpha(currT,1:3));
    % end
    
    % plot(scaledK(1:end-1), currField*spacerVec(tInd),'LineWidth',2,'Color',tcaAlpha((tInd),:));
    % plot(scaledK(1:end-1), currField*spacerVec(tInd),'LineWidth',2,'Color',tcaAlpha(selectTimes(tInd),:));
    % scatter(scaledK(xCut:end-1), squeeze(storeMat(xCut:end,zInd,currT))*spacerVec(tInd),16,'filled','MarkerFaceColor',tcaAlpha(currT,1:3));
    hold on
    % plot(scaledK(xCut:end-1), squeeze(storeMat(xCut:end,currZ,currT))*spacerVec(tInd),'LineWidth',1,'Color',timeColorArray(currT,:));
    plot(scaledK(xCut:end-1), avged(:,tInd)*spacerVec(tInd),'LineWidth',1,'Color',[.1 .1 .1]);
   
end

set(gca,'FontSize',15)

xlabel(xtitle)
ylabel(ytitle)
title(titleTag)
xlim(xBnds)
ylim(yBnds)
temp = gca;
% temp.YTickLabel = [];
% temp.XTickLabel = [];
cbh = colorbar;
colormap(timeColorArray(selectTimes,:));
cbh.Ticks = ([min(selectTimes) max(selectTimes)] - min(selectTimes))/(max(selectTimes)- min(selectTimes)) ; %Create 8 ticks from zero to 1
% cbh.Ticks = (selectTimes - min(selectTimes))/(max(selectTimes)- min(selectTimes)) ; %Create 8 ticks from zero to 1
cbh.TickLabels = num2cell(([min(selectTimes) max(selectTimes)]-tFlip)*deltaT) ; 
set(gca,'XScale','log','YScale','log');
box on

%% Plot spectra, movemean, and reference slope
% Select times for full color + transpacrency
deltaT = 0.5;
zInd = 3;
selectTimes = [6 14];
spacerLen = 0;
alphaTimes = [];
alphaVal = 0.2;
xmin = 1/185;
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
avged  = movmean(squeeze(storeMat(xCut:end,zInd,selectTimes)),movkern);
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
    scatter(scaledK(xCut:end-1), squeeze(storeMat(xCut:end,zInd,currT))*spacerVec(tInd),16,'filled','MarkerFaceColor',timeColorArray(currT,:));
    % plot(scaledK(xCut:end-1), squeeze(storeMat(xCut:end,currZ,currT))*spacerVec(tInd),'LineWidth',1,'Color',timeColorArray(currT,:));
    plot(scaledK(xCut:end-1), avged(:,tInd)*spacerVec(tInd),'LineWidth',1,'Color','black');
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
ycrd1 = storeMat(kInd1+1,zInd,selT);
% ycrd2 = storeMat(kInd2 + 1,currZ,selT);
yCrd2Slope = ycrd1*exp(slopeFit*diff(log(xCrds)));
plot(xCrds', [ycrd1 yCrd2Slope]','LineWidth',2,'Color','black')
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
avged  = movmean(squeeze(storeMat(xCut:end,zInd,selectTimes)),movkern);
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
zInd = 1;
selInds = 5:600;
% loglog(scaledK(4:end-1), movmean(squeeze(storeMat(4:end,currZ,selectTimes)),5),'LineWidth',1);
loglog(scaledK(selInds), squeeze(storeMat(selInds,zInd,selectTimes)),'LineWidth',1);
hold on
% scatter(scaledK(1:end-1), squeeze(storeMat(:,currZ,selectTimes)),15,'filled');
scatter(scaledK(selInds), squeeze(storeMat(selInds,zInd,selectTimes)),7,'filled');
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
loglog(scaledK(1:end-1), movmean(squeeze(storeMat(1:end,zInd,selectTimes)),5),'LineWidth',2,'LineStyle','--','Color',[.1 .18 .1]);
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