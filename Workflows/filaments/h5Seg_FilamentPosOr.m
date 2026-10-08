% Load data
% ??? - 09/28/2023
% dataDir = '<redacted original absolute path>';
dataDir = 'Session 45, Exp 3';
% saveMoDir = '<redacted original absolute path>';
saveMoDir = 'Session 45, Exp 3';
h5NameForm = 'Time%06i_gcorr_filaments_Probabilities.h5';
saveNameForm = 'Time%06i_filaments.tif';
saveStructForm = 'Time%06i_objProps.mat';
voxDims = [.37 .37 1.5];
scaleImg = [1 1 4];
% selectTimes = 1;
selectTimes = 1:40;
currChan = 2;
threshval = .7;
pixSize = 11*2/60;
cutOffLen1 = 2/pixSize;    cutOffLen2 = Inf/pixSize;
cutOffAspect = 2.5;

%% Make directory
saveDir = fullfile(saveMoDir, sprintf('%dIntThresh_%iVolThresh_%iAspectThresh', threshval, cutOffLen1, cutOffAspect));
if ~exist(saveDir)
    mkdir(saveDir);
end

%%
for tInd = 1:numel(selectTimes)
    %% Load a file
    currT = selectTimes(tInd);
    currH5 = permute(h5read(fullfile(dataDir,sprintf(h5NameForm,currT)),'/exported_data'),[1 3 2 4]);     %Remember to permute x and y! 
    selData = squeeze(currH5(currChan,:,:,:));
    
    %% get properties
    bwimg = imbinarize(selData,threshval);
    objProps = regionprops3(bwimg,'EigenVectors','EigenValues','Centroid','Orientation','PrincipalAxisLength');
    
    %% Keep objects above thresh vol and aspect ratio
    % ASPECT RATIO
    % Collect all eigenvalues and eigenvectors
    allEVals = vertcat(objProps.EigenValues{:});
    allEigVecs = horzcat(objProps.EigenVectors{:})';
    % Scale vectors by voxel dimensions, then by eigenvalues 
    scaledEigVecs = allEigVecs.*voxDims;
    rescaledEigVecs = scaledEigVecs.*allEVals;
    % Aspect ratio is ratio of "principle" eigenvec to mag. of other evecs.
    aspectRatios = sqrt(sum(rescaledEigVecs(1:3:end,:),2).^2)./...
        sqrt( sum(rescaledEigVecs(2:3:end,:).^2,2) + sum(rescaledEigVecs(3:3:end,:).^2,2) );
    % Define cutoff of aspect ratio
    arLogic = aspectRatios >= cutOffAspect;
    
    % LENGTH
    % Collect lengths from principle axis lengths
    allLens = objProps.PrincipalAxisLength(:,1);
    % Rescale lengths by voxel-scaled principle eigenvector magnitudes
    scaleLens = allLens.*sqrt(sum(scaledEigVecs(1:3:end,:).^2,2));
    % Define cutoff of lengths
    lenLogic = (allLens >= cutOffLen1) & (allLens <= cutOffLen2);

    %% Isolate objects of interest
    bwimgIDs = bwconncomp(bwimg);
%     screenedIdx = find(arLogic );
    screenedIdx = find(arLogic & lenLogic);
    currObjs = consMatLnB(selData,vertcat(bwimgIDs.PixelIdxList{screenedIdx}));

    %% Rebuild conncomp object and regionprop table
    reducedConnComp = bwimgIDs; 
    reducedConnComp.PixelIdxList = reducedConnComp.PixelIdxList(screenedIdx);
    reducedConnComp.NumObjects = numel(screenedIdx);
    reducedObjProps = objProps(screenedIdx,:);

    %% Save as tiff
    save3DTiff(uint8(currObjs*240),fullfile(saveDir,sprintf(saveNameForm, currT)));
    save3DTiff(imresize3(uint8(currObjs*240),scaleImg.*size(currObjs)),fullfile(saveDir,sprintf(['Resized_', saveNameForm], currT)));
    save(fullfile(saveDir,sprintf(saveStructForm, currT)),'reducedObjProps','reducedConnComp');

%% plot distribution of x-y
temp = ( abs(rescaledEigVecs(1:3:end,1)) - abs(rescaledEigVecs(1:3:end,2)) )./( abs(rescaledEigVecs(1:3:end,1)) + abs(rescaledEigVecs(1:3:end,2)) );
temp = temp(~isnan(temp));
histogram(temp,-.95:.01:.95)
hold on
% median(temp)

end

%% 



%% 
test = consMatLnB(selData,vertcat(bwimgIDs.PixelIdxList{selInds}));
test2 = zeros([size(test,1:2),3]);
test2(:,:,1) = selData(:,:,15);
test2(:,:,2) = currObjs(:,:,15);
test2(:,:,3) = test(:,:,15);

%% Check
selCens = eigCutObjs.Centroid;
cenInds = sub2ind(size(selData), round(selCens(:,2)),round(selCens(:,1)),round(selCens(:,3)));
% selData(cenInds) = 4;

%% What's the goal?
% track objects. get objects that aren't moving and objects that ARE moving

%%  Verify locations
    cens = objProps.Centroid(selInds2,:);
    evecs1 = horzcat(objProps.EigenVectors{selInds2}); evecs1 = evecs1(:,1:3:end)';
    evecs1 = [evecs1(:,2) evecs1(:,1) evecs1(:,3)];
    majLen = vertcat(objProps.PrincipalAxisLength(selInds2,:)); majLen = majLen(:,1);
    cenlim1 = (cens - majLen/2.*evecs1)';  cenlim2 = (cens + majLen/2.*evecs1)';
plot3([cenlim1(1,:); cenlim2(1,:)],[cenlim1(2,:); cenlim2(2,:)],[cenlim1(3,:); cenlim2(3,:)]);
xlim([100 200])
ylim([100 200])
zlim([1 80])
allVox = vertcat(bwimgIDs.PixelIdxList{selInds2});
[allY,allX,allZ] = ind2sub(size(currObjs),allVox);
hold on
scatter3(allX, allY, allZ,1,'filled');
xlabel('x')
ylabel('y')
zlabel('z')
%% select obj
selObj = 3591;
selVox = vertcat(bwimgIDs.PixelIdxList{selInds2(selObj)});
[selY,selX,selZ] = ind2sub(size(currObjs),selVox);
testImg = zeros(size(bwimg));
testImg(selVox) = 1;
selEVec = objProps.EigenVectors{selInds2(selObj),1};    selEVec = selEVec(:,1)';
selEVec = [selEVec(:,2) selEVec(:,1) selEVec(:,3)];
selLen = objProps.PrincipalAxisLength(selInds2(selObj),:);
selCen = objProps.Centroid(selInds2(selObj),:);
    
cenlim1 = (selCen - selLen(1)/2.*selEVec)';  cenlim2 = (selCen + selLen(1)/2.*selEVec)';
scatter3(selX,selY,selZ)
hold on
scatter3(selCen(1), selCen(2), selCen(3))
plot3([cenlim1(1,:); cenlim2(1,:)],[cenlim1(2,:); cenlim2(2,:)],[cenlim1(3,:); cenlim2(3,:)]);
%     test = evecs1.*repmat(vecLen,3,1);
