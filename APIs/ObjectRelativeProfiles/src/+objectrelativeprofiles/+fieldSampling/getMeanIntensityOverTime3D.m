%% Data info
% dataDir = "<redacted original absolute path>";
dataDir = "Session 35, Exp 1";
dataName = "Time%06i_16bitcropped.tif";
% waveLengths = [560, 647];
selectTimes = 1:50;
pixSize = 2*11/20;
firstTif = tiffreadVolume(fullfile(dataDir,sprintf(dataName,selectTimes(1))));

colorsMap = meldNcolors([0 0 1; 1 0 0], numel(selectTimes));

%% Iterate through time and collect intensity info
medZsPerT = zeros(numel(selectTimes), size(firstTif,3));
totInts = zeros(numel(selectTimes),1);

for tInd = 1:numel(selectTimes)

    currTif = double(tiffreadVolume(fullfile(dataDir,sprintf(dataName,selectTimes(tInd)))));
    medZsPerT(tInd,:) = squeeze(median(currTif, [1 2]));
    totInts(tInd) = sum(currTif(:));

end

%% Plot median intensities over time
figure
for tInd = 1:numel(selectTimes)
    plot(pixSize*(1:size(currTif,3)), medZsPerT(tInd,:), 'Color', colorsMap(tInd,:));
    hold on
end
xlabel('Chamber Height (um)')
ylabel('Median Intensity')
title('Median intensity per z over time')
set(gca,'FontSize', 15)
colorbar
colormap(colorsMap)

%% Plot median intensities bleach corrected over time
figure
for tInd = 1:numel(selectTimes)
    plot(pixSize*(1:size(currTif,3)), medZsPerT(tInd,:)/totInts(tInd), 'Color', colorsMap(tInd,:));
    hold on
end
xlabel('Chamber Height (um)')
ylabel('Median Intensity')
title('Median intensity per z bleach corr. over time')
set(gca,'FontSize', 15)
colorbar
colormap(colorsMap)
xlim([ min(pixSize*(1:size(currTif,3)))-2 max(pixSize*(1:size(currTif,3))) + 2] )

%% Plot median intensities bleach corrected and corrected by first profile over time
figure
corrMeds = rdivide(medZsPerT, medZsPerT(1,:));
for tInd = 1:numel(selectTimes)
    plot(pixSize*(1:size(currTif,3)), corrMeds(tInd,:)/totInts(tInd), 'Color', colorsMap(tInd,:));
    hold on
end
xlabel('Chamber Height (um)')
ylabel('Median Intensity')
title('Median intensity bleach corr. renormalized by t1 per z over time')
set(gca,'FontSize', 15)
colorbar
colormap(colorsMap)
xlim([ min(pixSize*(1:size(currTif,3)))-2 max(pixSize*(1:size(currTif,3))) + 2] )

%%

% for currInd = 1:numel(waveLengths)
%     currTif = tiffreadVolume(fullfile(dataDir,sprintf(dataName,waveLengths(currInd))));
% 
%     meanInts = squeeze(mean(mean(currTif,1),2));
%     scatter(1:numel(meanInts), meanInts/meanInts(1),'filled')
%     hold on
% 
% end

set(gca, "FontSize", 15);
xlabel("Time (frames)")
ylabel("Mean intensity fraction")
legend("560nm MTs", "647nm MTs")