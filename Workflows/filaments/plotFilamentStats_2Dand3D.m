%% Expects data spat out by getFilamentStats_2Dand3D and plots
% 2023-11-14 - 2023-11-27
%% Data info
% baseDir = '<redacted original absolute path>';
baseDir = 'Session 83';
segSuperDir = fullfile(baseDir,'8 Filament Detection');
rawSuperDir = fullfile(baseDir,'0 Raw Data');
% segSubDir = 'p200_ChamberSide_GaussCorr Segmentations Statistics';
segSubDirForm = 'Analyzed Filament Data';
% segSubDirForm = '*31hrsOut*';  
% segSubDirForm = '*2hrsOut'; 
allSubDirs = (fullfile(segSuperDir,segSubDirForm));
rawSubDirForm = segSubDirForm; allRawDirs = dir(fullfile(rawSuperDir,rawSubDirForm));
objNameForm = 'Filament Statistics %03i.mat';
selFields2D = {'Centroid','Area','MinorAxisLength','MajorAxisLength','Orientation','Slice_Index'};
pixSize = 11*2/60;
timesVec = 1:90;

%% Concatenate and label indices of all requested data
% Super loop over multiple directories/data sets
allallrp2D = struct();
for subInd = 1:1
% for subInd = 1:numel(allSubDirs)
    % Concatenate object statistics
    % segSubDir = allSubDirs;
    % segSubDir = allSubDirs(subInd).name;
    allrp2D = struct();
    currDir = allSubDirs;
    % currDir = fullfile(segSuperDir,segSubDir);
    % Iterate over data sets in current directory/data set
    for objInd = 1:numel(timesVec)
        % Load current data set
        currObj = timesVec(objInd);
        currObjDir = fullfile(currDir,sprintf(objNameForm,currObj));
        if ~isfile(currObjDir)
            continue
        end
        load(currObjDir);
        % Isolate requested fields
        selFieldVals2D = structFields2Cell(rp2D,selFields2D);
        temprp2D = addFieldsStruct(struct(),selFields2D,selFieldVals2D);
        temprp2D = addFieldStruct(temprp2D,'Object_Index',repmat(currObj,numel(rp2D),1));
        % Concatenate data
        if numel(allrp2D) == 1
            allrp2D = temprp2D;
        else
            allrp2D = [allrp2D, temprp2D];
        end    
    end

    % Differentiate based on data set, then concatenate
    allrp2D = addFieldStruct(allrp2D, 'Sub_Dir_Index', repmat(subInd,numel(allrp2D),1));
    if subInd == 1
        allallrp2D = allrp2D;
    else
        allallrp2D = [allallrp2D, allrp2D];
    end
end
%% %%%%%%%%%%%%%%%%%%%%%%%%%  ANALYSES  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% %%
% Consider rewriting to have values stored in vectors directly from loaded
% structures (individual)
%% Convert structures to array for analysis (consider storing in cell with key)
sliceInds = [allallrp2D.Slice_Index];
objInds = [allallrp2D.Object_Index];
subIndsVec = [allallrp2D(:).Sub_Dir_Index];
CoMs = vertcat(allallrp2D.Centroid)';
allVols = [allallrp2D.Area];
allOris = [allallrp2D.Orientation];
allThetas = pi/180*allOris;
majAxes = [allallrp2D.MajorAxisLength]; minAxes = [allallrp2D.MinorAxisLength];
aspectRatio = majAxes./minAxes;
cos2th = cos(2*allThetas);
% Transform the two points (1,0) and (-1,0) s.t. they share orientation of
% appropriate object (stored in Orientation)
backboneXs = CoMs(1,:) + [cos(allThetas); -cos(allThetas)].*majAxes/2;
backboneYs = CoMs(2,:) + [-sin(allThetas); sin(allThetas)].*majAxes/2;

%% Save the above vectors, then clear structs
clear allallrp2D allrp2D rp2D rp3D temprp2D
save(fullfile(segSuperDir,'Concatenated_2D_Info.mat'),'allOris','allThetas','CoMs',...
    'allVols','sliceInds','objInds','subIndsVec','majAxes','minAxes','backboneXs','backboneYs');

%% Load
load(fullfile(segSuperDir,'Concatenated_2D_Info.mat'));
aspectRatio = majAxes./minAxes;

%% Define volume filter, aspect ratio filter, orientation filter, slice filter
allVec = ones(size(sliceInds));

sizeFilt = allVols > 8;         % pixels (allVols)
arFilt = aspectRatio > 1.5;       % Ratio major/minor axes (aspectRatio)
sliceFilt = allVec;             % slice index   (sliceInds)
lengthFilt = majAxes > 2;       % pixels (majAxes)
dataSetFilt = ismember(subIndsVec,1);  % Numbered data set (subIndsVec)
logicVec = sizeFilt & arFilt & sliceFilt & lengthFilt & dataSetFilt;

%% View selection of filaments
% imgDir = '<redacted original absolute path>';
imgDir = 'Session 83';
imgName = 't%03i_illBleachCorr16bit_560.tif';
% saveDir = '<redacted original absolute path>';
saveDir = 'Session 83';
saveName = 'Time%06i_MTsDenseSparseOverlay.png';
selTimes = 1:50;
currSlice = [39 40 41];

for tInd = 1:numel(selTimes)
    currT = selTimes(tInd);
    sliceFilt = ismember(sliceInds, currSlice);
    timeFilt = objInds == currT;
    curr2DLogic = sliceFilt & timeFilt;
    currLogic = logicVec & curr2DLogic;
    % imgDir = 'Session 83';
    % imgName = sprintf('Time%06i_raw647.tif',currTime);
    currTif = tiffreadVolume(fullfile(imgDir,sprintf(imgName,currT)));
    imagesc(currTif(:,:,round(mean(currSlice))));
    colormap('gray')
    clim([7700 18200])
    hold on
    plot(backboneXs(:,curr2DLogic),backboneYs(:,curr2DLogic),'LineWidth',2,'Color','g');
    plot(backboneXs(:,currLogic),backboneYs(:,currLogic),'LineWidth',1,'Color','r');
    hold off
    imwrite(getframe(gcf).cdata,fullfile(saveDir,sprintf(saveName,currT)));
end

%% Histogram of orientations over z
histBins = -90:6:90;
storeNums = zeros(numel(histBins)-1,numel(unique(sliceInds)));
figure
for index = unique(sliceInds)    
    newVec = sliceInds == index & logicVec;
    [binNum,binEdge] = histcounts(allOris(newVec),histBins);
    storeNums(:,index) = binNum;
    plot((binEdge(1:end-1)+binEdge(2:end))/2,binNum,'Color',[index/max(sliceInds) 0 (1 - index/max(sliceInds))]);
    hold on
end

%% Plot mean cos(2_theta) vs. z slice
meanOrs = zeros(numel(unique(sliceInds)),1);
stdOrs = meanOrs;
for currSlice = unique(sliceInds)
    currLogic = logicVec & (sliceInds == currSlice);
    meanOrs(currSlice) = mean(cos2th(currLogic));
    stdOrs(currSlice) = std(cos2th(currLogic));
end
figure
errorbar(unique(sliceInds),meanOrs,stdOrs);
xlabel('Z slice')
ylabel('Mean cos(2\theta)')
title('Mean degree of filament alignment over z')
set(gca,'FontSize',18)
ylim([-1.1 1.1])
xlim([0 max(unique(sliceInds))+1])

%% Plot histogram of cos(2theta)
figure
histogram(cos2th(logicVec), 40);
xlabel('Cos(2\theta)')
ylabel('Counts')
title('Distribution of Cos(2\theta)')
set(gca,'FontSize',18)

%% Plot histogram of Major Axis Length
histEdges =  0:.2:10;
figure
lengths= majAxes(logicVec)*pixSize;
histogram(lengths,histEdges);
xlabel('Detected MT Lengths (um)')
ylabel('Counts')
title('Distribution of MT Lengths (p200)')
set(gca,'FontSize',18)
hold on

% Log normal fit
binVals = histcounts(lengths,histEdges);
fitParams = lognfit(lengths);
valEdges = histEdges(histEdges>0);
logNormVals = 1./(valEdges*fitParams(2)*sqrt(2*pi))...
    .*exp(- (log(valEdges) - fitParams(1)).^2./(2*fitParams(2)^2));
logNormVals = logNormVals/sum(logNormVals);
nonZeroVals = binVals > 0;
scaleVal = sum(logNormVals(nonZeroVals))/sum(logNormVals);
plot(valEdges,logNormVals*scaleVal*sum(binVals));

fprintf('Mean = %d, Std = %d, Mode = %d\n', mean(lengths),std(lengths),mode(lengths))

% annotation('textbox',[0.65 0.95 0.05 0.25],'String',sprintf('Mean = test\nStd = test'))
%% Define image name format
% imgDir = 'Session 56, Exp 1';
% imgName = 'Time%06i_Filaments_gaussCrop.tif';

% imgDir = '<redacted original absolute path>';
imgDir = 'Session 83';
imgName = 'Time000001_raw647.tif';
currTif = tiffreadVolume(fullfile(imgDir,imgName));

%% Further refinement
aspectRange = [2.6 2.8];
arLogic = aspectRatio > min(aspectRange) & aspectRatio < max(aspectRange);
currLogic = selOriLogic & arLogic;
plot(backboneXs(:,currLogic),backboneYs(:,currLogic),'LineWidth',3,'Color','b');

%% Aspect ratio distribution for orientation range
selOris = (abs(allOris) > min(oriRange)) & (abs(allOris) < max(oriRange));
figure
histogram(majAxes(selOris));

%% Define volume filter, aspect ratio filter, orientation filter, slice filter
figure
hold on
for subInd = 1:4
    allVec = ones(size(sliceInds));
    sizeFilt = allVols > 8;     % pixels (allVols)
    arFilt = aspectRatio > 1;   % Ratio major/minor axes (aspectRatio)
    sliceFilt = allVec;         % slice index   (sliceInds)
    lengthFilt = majAxes > 5;   % pixels (majAxes)
    subFilt = subIndsVec == subInd;
    logicVec = sizeFilt & arFilt & sliceFilt & lengthFilt & subFilt;
    histogram(cos2th(logicVec),-1:.02:1)
end

%% select one slice and plot lines over image
for index = unique(sliceInds)
    imshow(fullfile(segSuperDir,segSubDir,sprintf(imgName,index)));
    currLogic = (sliceInds == index) & (aspectRatio > 1);
    hold on
    plot(backboneXs(:,currLogic),backboneYs(:,currLogic),'LineWidth',2);
    hold off
    ginput(1);
end

%% Scattered interpolant object for orientation field (3D)
imgDims = size(currTif);
[xmesh3, ymesh3, zmesh3] = meshgrid(1:imgDims(1),1:imgDims(2),1:imgDims(3));

tInd = 30;
timeLogic = (objInds == tInd);
currLogic = logicVec & timeLogic;
scobj3 = scatteredInterpolant(CoMs(1,currLogic)', CoMs(2,currLogic)', sliceInds(currLogic)', cos2th(currLogic)');
scVals3 = scobj3(xmesh3(:),ymesh3(:),zmesh3(:)); 

%% Scattered interpolant object for orientation field (2D)
imgDims = size(currTif);
[xmesh2, ymesh2] = meshgrid(1:imgDims(1),1:imgDims(2));

tInd = 1;
timeLogic = (objInds == tInd);
scmat2 = zeros(size(xmesh3));
for zInd = 1:numel(unique(sliceInds))
    sliceLogic = (sliceInds == zInd);
    currLogic = logicVec & timeLogic & sliceLogic;
    if sum(currLogic) == 0
        continue
    end
    scobj2 = scatteredInterpolant(CoMs(1,currLogic)', CoMs(2,currLogic)', cos2th(currLogic)');
    scVals2 = scobj2(xmesh2(:),ymesh2(:)); 
    scmat2(:,:,zInd) = reshape(scVals2,[imgDims(2) imgDims(1)]);
end
boundedSCMat2 = consMatLnB(scmat2,abs(scmat2) < 1);

%% Overlay backbones over slices of orientation field 2D
selSlice = 1;  
oriRange = [-180 180];
figure
imagesc(boundedSCMat2(:,:,selSlice));
oriLogic = (abs(allOris) > min(oriRange)) & (abs(allOris) < max(oriRange));
sliceLogic =  (sliceInds == selSlice);
timeLogic = (objInds == tInd);
% currLogic = sliceLogic & oriLogic & logicVec;
currLogic = logicVec & sliceLogic & timeLogic;
hold on
plot(backboneXs(:,currLogic),backboneYs(:,currLogic),'LineWidth',2,'Color','r');

%% 
% saveDir = '<redacted original absolute path>';
saveDir = 'Session 56, Exp 1';
saveNameForm = 'Time%06i_orientations.tif';
scmat = reshape(scVals,[imgDims(2) imgDims(1) imgDims(3)]);
boundedSCMat = consMatLnB(scmat,abs(scmat) < 1);
orthosliceViewer(boundedSCMat);


%% Feed mesh coords

%% DISPLAY %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Define volume filter, aspect ratio filter, orientation filter, slice filter
allVec = ones(size(sliceInds));

sizeFilt = allVols > 8;         % pixels (allVols)
arFilt = aspectRatio > 1;       % Ratio major/minor axes (aspectRatio)
sliceFilt = allVec;             % slice index   (sliceInds)
lengthFilt = majAxes > 2;       % pixels (majAxes)
dataSetFilt = ismember(subIndsVec,1);  % Numbered data set (subIndsVec)
logicVec = sizeFilt & arFilt & sliceFilt & lengthFilt & dataSetFilt;


% sliceInds = [allallrp2D.Slice_Index];
% objInds = [allallrp2D.Object_Index];
% subIndsVec = [allallrp2D(:).Sub_Dir_Index];

%% Display backbones over image
selSlice = 1; selTime = 1; selDir = 2;
oriRange = [-180 180];
imgName = 'img_channel000_position000_time%09i_z000.tif';
figure
currTif = double(tiffreadVolume(fullfile(rawSuperDir, allRawDirs(selDir).name,sprintf(imgName,selTime-1))));
imagesc(currTif(:,:,selSlice));
clim([3000 7000])
colormap('gray')
figure
imagesc(currTif(:,:,selSlice));
clim([3000 7000])
colormap('gray')
oriLogic = (abs(allOris) > min(oriRange)) & (abs(allOris) < max(oriRange));
sliceLogic =  (sliceInds == selSlice);
timeLogic = (objInds == selTime);
% currLogic = sliceLogic & oriLogic & logicVec;
currLogic = logicVec & sliceLogic & timeLogic;
hold on
plot(backboneXs(:,currLogic),backboneYs(:,currLogic),'LineWidth',2);
