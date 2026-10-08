%% Data directory info
% imgDir = '<redacted original absolute path>';
imgDir = 'Session 35, Exp 1';
imgNameForm = 'Time%06i_16bitcropped.tif';
% trajInfoDir = '<redacted original absolute path>';
trajInfoDir = 'Session 35, Exp 1';
objIDFile = 'objectIDs_cropped.mat';
trajInfoFile = 'Ordered_Trajectories_Struct.mat';

% selectTimes = 15:30;
selectTrajs = [1 7 18 19];
pixelScale = 11*2/20;

%% Load data
load(fullfile(trajInfoDir, objIDFile));
load(fullfile(trajInfoDir, trajInfoFile));
totTable = table2array(getTrajObjTimeTable(trajStruct));
selectTimes = unique(totTable(:,1));

%% Generate storage structure
profileStruct = struct();

%% Iterate through time
for timeInd = 1:numel(selectTimes)

%% Load an image
% tInd = 10;                      %structure index
currT = selectTimes(timeInd);      %global frame number
currTif = double(tiffreadVolume(fullfile(imgDir, sprintf(imgNameForm, selectTimes(timeInd)))));

%% Generate full blobmat
allBlobsCurrT = zeros(size(currTif));
allBlobsCurrT(vertcat(objIDs(timeInd).pixIDs{:})) = 1;

%% Level sets from distance transform
distMat = bwdist(allBlobsCurrT);
invDistMat = bwdist(~allBlobsCurrT);
fullDistMat = distMat - invDistMat;

%% Calculate median intensity outside of all objects
medIntOut = median(consMatLnB(currTif, ~allBlobsCurrT),'all');

%% Select blob mat for single traj
% selectedTraj = 1;
for trajInd = 1:numel(selectTrajs)
%Define trajectory
currTraj = selectTrajs(trajInd);
% Get objects and trajectories in current time point
objsInFrame = totTable((totTable(:,1) == currT),2);
trajsInFrame = totTable((totTable(:,1) == currT),3);
% Get index of object in index repository for current time and traj
trajIndInObjStruct = objsInFrame(trajsInFrame == currTraj);
% Construct matrix with isolated object in current trajectory (if request)
singleBlob = zeros(size(currTif));
if ~isempty(trajIndInObjStruct)
    % Construct single blob tif
    singleBlob(objIDs(timeInd).pixIDs{trajIndInObjStruct}) = 1;
end

%% Generate level sets for single blob mat
distMatSingle = bwdist(logical(singleBlob));
invDistMatSingle = bwdist(~logical(singleBlob));
singleDistMat = distMatSingle - invDistMatSingle;

%% Localized dist mat       ****Find way to split dist transform into piecewise contributions in one step
locDistInds = fullDistMat == singleDistMat;
singleBlobDist = round(consMatLnB(fullDistMat,locDistInds));

%% Int profile rough vs dist
meanInts = zeros(numel(unique(singleBlobDist(:))),1);
stdInts = meanInts;
dataPointCount = meanInts;
ringDists = unique(singleBlobDist(:));

% Iterate through time and store intensities
for currRing = 1:numel(ringDists)
    currInds = singleBlobDist == ringDists(currRing);
    meanInts(currRing) = mean(currTif(currInds));
    dataPointCount(currRing) = sum(currInds(:));
    stdInts(currRing) = std(currTif(currInds));
end

ringDists(ringDists < 0) = ringDists(ringDists < 0) + 1;    %shift outer most ring to distance 0

%% Mean intensity in given object
meanIntIn = mean(consMatLnB(currTif, logical(singleBlob)),'all');
stdIntIn = std(consMatLnB(currTif, logical(singleBlob)),0,'all');

%% Store in structure
profileStruct(timeInd, trajInd).EdgeDist = ringDists;
profileStruct(timeInd, trajInd).MeanInts = meanInts;
profileStruct(timeInd, trajInd).ErrorInts = stdInts;
profileStruct(timeInd, trajInd).NumPoints = dataPointCount;
profileStruct(timeInd, trajInd).MedInt = medIntOut;
profileStruct(timeInd, trajInd).MeanInt = meanIntIn;
profileStruct(timeInd, trajInd).StdInt = stdIntIn;
profileStruct(timeInd, trajInd).ObjVol = sum(logical(singleBlob),'all');


end

end

%% Mean intensities in objects over time
medInts = vertcat(profileStruct(:,1).MedInt);
figure
for trajInd = 1:size(profileStruct,2)

    currMeans = vertcat(profileStruct(:,trajInd).MeanInt)./medInts;
    currVars = vertcat(profileStruct(:,trajInd).StdInt);
    nonZero = find(currMeans > 0);
%     errorbar(selectTimes,currMeans, currVars,'o')
%     scatter(selectTimes(nonZero),currMeans(nonZero)/max(currMeans(nonZero)),'filled')
    loglog(selectTimes(nonZero),currMeans(nonZero)/max(currMeans(nonZero)))
%     loglog(selectTimes(nonZero),currMeans(nonZero))
hold on
end
title('Mean Intensity per Trajectory Over Time')
xlabel('Time (frame)')
ylabel('Intensity/Voxel')
set(gca,'FontSize',15)
legend("Object 1", "Object 7", "Object 18", "Object 19")

%% Total intensity over time
medInts = vertcat(profileStruct(:,1).MedInt);
figure
for trajInd = 1:size(profileStruct,2)

    currMeans = vertcat(profileStruct(:,trajInd).MeanInt)./medInts;
    nonZero = find(currMeans > 0);
    currPts = vertcat(profileStruct(:,trajInd).ObjVol);
%     loglog(selectTimes(nonZero), currMeans(nonZero).*currPts(nonZero))
%     scatter(selectTimes(nonZero), currMeans(nonZero).*currPts(nonZero)/max(currMeans(nonZero).*currPts(nonZero)),'filled')
    loglog(selectTimes(nonZero), currMeans(nonZero).*currPts(nonZero)/max(currMeans(nonZero).*currPts(nonZero)))
    hold on
end
title('Total Intensity per Trajectory Over Time')
xlabel('Time (frame)')
ylabel('Intensity')
set(gca,'FontSize',15)
legend("Object 1", "Object 7", "Object 18", "Object 19")

%% Plot contents of profileStruct
colorsMap = meldNcolors([0 0 1; 1 0 0], size(profileStruct,1));
medInts = vertcat(profileStruct(:,1).MedInt);
close all
for timeInd = 1:numel(selectTimes)
    
    for trajInd = 1:numel(selectTrajs)
        figure(trajInd)
        scatter(profileStruct(timeInd,trajInd).EdgeDist*pixelScale, profileStruct(timeInd,trajInd).MeanInts/medInts(timeInd), 12, colorsMap(timeInd,:),'filled');
%         scatter(profileStruct(timeInd,trajInd).EdgeDist*pixelScale, profileStruct(timeInd,trajInd).MeanInts/medInts(timeInd), 12, colorsMap(timeInd,:),'filled');
        hold on

    end
end

%% Get maxes and mins
minInner = -100*ones(size(profileStruct,1),1);
maxOuter = -minInner;
for timeInd = 1:numel(selectTimes)
    for trajInd = 1:numel(selectTrajs)
        currEdges = profileStruct(timeInd,trajInd).EdgeDist;
        minInner(timeInd) = max(min(currEdges), minInner(timeInd));
        maxOuter(timeInd) = min(max(currEdges), maxOuter(timeInd));
    end
end

%% Average over trajectories
avgsOverTrajs = struct();
for timeInd = 1:numel(selectTimes)
    currTots = 0;
    avgsOverTrajs(timeInd).WeightedCounts = 0;
    for trajInd = 1:numel(selectTrajs)
        currMeans = profileStruct(timeInd, trajInd).MeanInts;
        currCount = profileStruct(timeInd, trajInd).NumPoints;
        currEdges = profileStruct(timeInd,trajInd).EdgeDist;
        minInd = find(currEdges == minInner(timeInd));
        maxInd = find(currEdges == maxOuter(timeInd));
        avgsOverTrajs(timeInd).WeightedCounts = (avgsOverTrajs(timeInd).WeightedCounts.*currTots + currMeans(minInd:maxInd).*currCount(minInd:maxInd));
        currTots = currTots + (currCount(minInd:maxInd));
        scatter(1:numel(avgsOverTrajs(timeInd).WeightedCounts),avgsOverTrajs(timeInd).WeightedCounts)
        hold on
%         test = profileStruct(timeInd,trajInd).MeanInts .* profileStruct(timeInd,trajInd).NumPoints;

    end
    avgsOverTrajs(timeInd).TotalNum = currTots;
end


%% 
minInd = max(minInner); maxInd = min(maxOuter);
test = zeros(size(profileStruct,1),numel(minInd:maxInd));
test2 = zeros(size(profileStruct,1),numel(minInd:maxInd));
for timeInd = 1:numel(selectTimes)
    for trajInd = 1:numel(selectTrajs)
        currMeans = profileStruct(timeInd, trajInd).MeanInts;
        currCount = profileStruct(timeInd, trajInd).NumPoints;
        currEdges = profileStruct(timeInd,trajInd).EdgeDist;
        currRange = curr
        test(timeInd, :) = test(timeInd,:) + currMeans(minInd:maxInd).*currCount(minInd:maxInd);
        test2(timeInd, :) = test2(timeInd,:) + currCount;
    end
end
