% Takes in connected component characteristics of filaments in 3D
% calculated via regionprops3. The script gives the option to filter out
% filaments based on degree of alignment along z axis to maximize
% contributions from in-plane filaments.
% Note: you may not have access to the indices, so can't replicate images
% 2025-04-17 - Rémi Boros

%%Data info
% setNum = 1;
% dataDir = '<redacted original absolute path>';
dataDir = 'Session 88, Exp 1';
% dataNameForm = '8bit%0.4i.h5';
pixSegName = 'Filament Statistics %03i.mat';
% saveDir = '<redacted original absolute path>';
saveDir = 'Session 88, Exp 1';
saveName = 'Time%06i_Histogram.png';

selectTimes = 1:10;
setBins = 1:.2:10;
pixDims = [11*2/60 11*2/60 0.7];
deltaT = 30;        % in seconds
tFormat = 'mm:ss';
approxScale = prod(pixDims).^(1/3);
dispBool=1;
yBnds = [0 1400];

% storeFields = {'Centroid','Volume','PrincipalAxisLength','EigenVectors','Directors','Lengths','AspectRatios'};
storeVar = 'rp3D';      % Name of field that fields are stored in (typically a table)
lenField = 'Lengths';   arField = 'AspectRatios';   orField = 'Directors';
volField = 'Volume';    cenField = 'Centroid';
% Cutoff info
cutAR = 1.5;
minVol = 4;
minLen = 1.5; maxLen = 50;
maxZAlign = 0.2;        % Dot product with z spans between 0 and 1; voxels may not be rescaled...

%% Use regionprobs and pixel segmentation
% Instantiate storage for values stored over all time
lensAllT = [];  volsAllT = [];  timeVec = [];
filtAllT = [];  filtZAllT= [];

% Iterate over time
for tInd = 1:numel(selectTimes)
    % Instantiate data variables for current index
    currT = selectTimes(tInd);
    stringTime = seconds(currT*deltaT);
    stringTime.Format = tFormat;
    currName = sprintf(pixSegName, currT);
    % Check that file exists
    if ~exist(fullfile(dataDir,currName),'file')
        continue
    end
    % Load data
    currData = load(fullfile(dataDir,currName),storeVar).(storeVar);

    % Isolate data
    allLens = currData.(lenField)*approxScale;
    allOris = currData.(orField);
    allARs = currData.(arField);
    allVols = currData.(volField);

    % Generate filtering logic matrices
    arLogic = allARs > cutAR;
    lenLogic = (allLens > minLen) & (allLens < maxLen);
    zLogic = abs(allOris(:,3)) < maxZAlign;
    volLogic = allVols > minVol;
    filtLogic = arLogic & lenLogic & volLogic;
    filtLogicZ = filtLogic & zLogic;

    % Store mean, median, std
    FilterTag = {'All';'Filtered (All Z)';'Filtered w/ Z'};
    Mean = [mean(allLens);mean(allLens(filtLogic));mean(allLens(filtLogicZ))];
    Median = [median(allLens);median(allLens(filtLogic));median(allLens(filtLogicZ))];
    StdDev = [std(allLens);std(allLens(filtLogic));std(allLens(filtLogicZ))];
    lenStats = table(FilterTag,Mean,Median,StdDev);

    % Store all lengths and logic super vectors
    lensAllT = [lensAllT; allLens];
    volsAllT = [volsAllT; allVols];
    filtAllT = [filtAllT; filtLogic];
    filtZAllT = [filtZAllT; filtLogicZ];
    timeVec = [timeVec; repmat(currT,size(allLens))];

    % Display histograms, if requested
    if dispBool == 1
        figure
        histogram(allLens,setBins);
        hold on
        histogram(allLens(filtLogic),setBins);
        histogram(allLens(filtLogicZ),setBins);
        legend(sprintf('All MTs - Mean %2.2fum',lenStats{1,2}),...
            sprintf('Size Filt. MTs - Mean %2.2fum',lenStats{2,2}),...
            sprintf('Size and Z Filt. MTs - Mean %2.2fum',lenStats{3,2}))
        set(gca,'FontSize',12);
        xlabel('MT Length (um)')
        ylabel('Count')
        ylim(yBnds)
        title(sprintf('Time %s',string(stringTime)));
        subtitle(sprintf('Cutoffs - Length: %2.2f, AR: %2.2f, Volume: %2.2f, n.z: %2.2f',minLen, cutAR, minVol, maxZAlign));
        saveas(gca,fullfile(saveDir,sprintf(saveName,currT)));
        close()
    end

end
filtAllT = logical(filtAllT);
filtZAllT = logical(filtZAllT);
save(fullfile(saveDir,sprintf('Time%i-%i_concatVars.mat',min(selectTimes),max(selectTimes))),...
    'lensAllT','volsAllT','timeVec','filtZAllT','filtAllT');

%% Display histogram of everything across all time, if requested
saveBool = 1;
yBndMax = [0 10000];

figure
histogram(lensAllT,setBins);
hold on
histogram(lensAllT(filtAllT),setBins);
histogram(lensAllT(filtZAllT),setBins);

legend(sprintf('All MTs - Mean %2.2fum',lenStats{1,2}),...
    sprintf('Size Filt. MTs - Mean %2.2fum',lenStats{2,2}),...
    sprintf('Size and Z Filt. MTs - Mean %2.2fum',lenStats{3,2}))
set(gca,'FontSize',12);
xlabel('MT Length (um)')
ylabel('Count')
ylim(yBndMax)
startTime = seconds(min(selectTimes)*deltaT);
startTime.Format = tFormat;
endTime = seconds(max(selectTimes)*deltaT);
endTime.Format = tFormat;
title(sprintf('Histograms over all times: %s-%s',string(startTime),string(endTime)));
subtitle(sprintf('Cutoffs - Length: %2.2f, AR: %2.2f, Volume: %2.2f, n.z: %2.2f',minLen, cutAR, minVol, maxZAlign));
if saveBool == 1
    saveas(gca,fullfile(saveDir,'AllTimes.png'));
end
close()

%% Fit log normal
% meanVal = mean(bigAxes)*pixScale;
% stdVal = std(bigAxes)*pixScale;
% % distVals = 1./(binEdges(2:end)*stdVal*sqrt(2*pi))*exp( - (log(binEdges(2:end) - meanVal).^2)/(2*stdVal^2));
% normTerm = ones(size(binEdges(2:end)))./(binEdges(2:end)*stdVal*sqrt(2*pi));
% distTerm =  exp( - ( (log(binEdges(2:end)) - meanVal).^2)/(2*stdVal^2) );
% logNorm = normTerm.*distTerm;
% 
% % scatter(binEdges(2:end), logNorm*sum(binCounts),'filled')
% hold off
