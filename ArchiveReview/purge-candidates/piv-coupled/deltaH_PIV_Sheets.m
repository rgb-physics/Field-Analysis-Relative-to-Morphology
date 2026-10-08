% Reconstruct binarized sheet surfaces, then use PIV to approximate change
% in height.
% 2025-07-30 - Rémi Boros
% baseMat = 'Session 63, Exp 4';
% pivDir = '<redacted original absolute path>';
pivDir = 'Session 28, Exp 6';
pivName = 't%03i_heightDiffs_meshes.mat';
% ilSegDir = '<redacted original absolute path>';
ilSegDir = 'Session 28, Exp 6';
ilSegName = 'SplitRegions_Time%06i.mat';
% structDir = '<redacted original absolute path>';
structDir = 'Session 28, Exp 6';
structName = 'DataStoreStructT%03i_scatInt_Bot.mat';

% structFields = {'TopSheet'};
% structFields = {'TopSheet','TopRegion'};
structFields = {'BotRegion','BotSheet'};
segVar = 'regionStruct';
deltaT = .5;
selTimes = 205:207;
% load metadata from piv (Run3DPIV.m) and segmentation (h5toMesh_homeoAndSplit.m)
load(fullfile(ilSegDir,'metadata.mat'));

maskDil = 5;
imgDil = 2;
window = 12;
spacing = [8 8 8];
methodNum = 2;
grdKern = 2;        % Use to remove grid artifacts in method 2

if ~exist(pivDir,'dir')
    mkdir(pivDir);
end
%% Iterate through time, do PIV
dskStrel = strel('disk',grdKern);
for tInd = 1:(numel(selTimes)-1)

    currT = selTimes(tInd);
    nextT = selTimes(tInd+1);
    
    % METHOD 1: Generate fields from segmentation structures
    if methodNum == 1
        pivVoxSize = segVoxSize;    pivMatSize = segSize;
        storeStruct = load(fullfile(ilSegDir,sprintf(ilSegName,currT)),segVar).(segVar); 
        img1 = struct2Mat_sheets(storeStruct,structFields,segSize); 
        storeStruct = load(fullfile(ilSegDir,sprintf(ilSegName,nextT)),segVar).(segVar); 
        img2 = struct2Mat_sheets(storeStruct,structFields,segSize); 
    elseif methodNum == 2
    % METHOD 2: Generate fields from vertices    
        pivVoxSize = [1 1 1];   pivMatSize = round(segVoxSize.*segSize);

        load(fullfile(structDir,sprintf(structName,currT)),'currStruct');
        img1 = rebuildMat(currStruct.v,segVoxSize,segSize,dskStrel,pivMatSize);
        load(fullfile(structDir,sprintf(structName,nextT)),'currStruct');
        img2 = rebuildMat(currStruct.v,segVoxSize,segSize,dskStrel,pivMatSize);

    end
    
    if imgDil > 0
        img1 = imdilate(logical(img1),strel('sphere',imgDil));
        img2 = imdilate(logical(img2),strel('sphere',imgDil));
    end
    
    % run PIV on difference of surfaces, using matrices from above
    mask1 = imdilate(logical(img1+img2),strel('sphere',maskDil));
    mask2 = mask1;
    
    [allShifts, cenCoords, shifts, validCenCoords, queryDims] = calc3DPIV_Sparse(img1, img2, mask1, mask2, spacing, window, 'gaussian');
    
    save(fullfile(pivDir,sprintf(pivName,currT)),'allShifts','cenCoords','shifts','validCenCoords','queryDims',"-mat");

    if tInd == 1
        save(fullfile(pivDir,'metadata.mat'),'pivMatSize','pivVoxSize','spacing','window')
    end
end
% 
%% Display quiver on sheets
% requires meshes and piv from heights
for tInd = 1:(numel(selTimes)-1)
    currT = selTimes(tInd);
    nextT = selTimes(tInd+1);
    % Load
    load(fullfile(structDir,sprintf(structName,currT)),'currStruct');
    filtVcut1 = round(currStruct.v);
    load(fullfile(structDir,sprintf(structName,nextT)),'currStruct');
    filtVcut2 = round(currStruct.v);
    load(fullfile(pivDir,sprintf(pivName,currT)));

    figure
    scatter3(filtVcut1(:,1),filtVcut1(:,2),filtVcut1(:,3),3,'green');
    hold on
    scatter3(filtVcut2(:,1),filtVcut2(:,2),filtVcut2(:,3),3,'blue');
    quiver3(validCenCoords(:,1),validCenCoords(:,2),validCenCoords(:,3),shifts(:,1),shifts(:,2),shifts(:,3),3,'red');
    box on
    axis equal
end



