% This script takes in directory/directories containing .tifs of segmented
% filaments from .h5s. It measures the statistics of said filaments without
% considering statistics from the 3rd dimension
% 2023-11-13 Rémi Boros
%% 
% ideally, loads .h5s directly, applies threshold, returns binarized
% objects. Then the script will do statistics
% baseDir = '<redacted original absolute path>';
baseDir = 'Session 87, Exp 2';
segDirSuper = fullfile(baseDir,'Filament Segmentations');
% subDirLabel = '*';
saveDirSuper = fullfile(baseDir,'Thresholded Filaments');
saveDirLabel = '%s';
h5Query = '*.h5';  h5String = '/exported_data';
h5Chans = 2; h5Thresh = 0.6;
binarizeBool = 1; saveBool = 0;
scaleFacts = [1 1]; pixSize = 11*2/40;
selFields2D = {'Centroid','Area','MinorAxisLength','MajorAxisLength','Orientation'};
selFields3D = {'Centroid','Volume','PrincipalAxisLength','EigenVectors'};

%% Iterate through h5 directories, convert contents
fileNames = dir(fullfile(segDirSuper,h5Query));
% Iterate through each file in the current directory; load and convert
% to binarized matrix; save, if requested
for fileInd = 1:numel(fileNames)
    newBool = 1;        % Used to define new storage struct in cases where no objects are observed in first z slice
    [~,currFileName,fileExt] = fileparts(fileNames(fileInd).name);
    currSeg = loadH5(fullfile(segDirSuper,[currFileName fileExt]),h5String,h5Chans);
    currMat = h5toTif(currSeg,scaleFacts,binarizeBool,h5Thresh,0);
    currSaveDir = saveDirSuper;
    if exist(currSaveDir,'dir') == 0
        mkdir(currSaveDir);
    end
    % Save, if requested
    if saveBool == 1        
        if exist(fullfile(currSaveDir,'Thresholded Filament Tifs'),'dir') == 0
            tifDir = fullfile(currSaveDir,'Thresholded Filament Tifs');
            mkdir(tifDir);
        end
        save3DTiff(currMat, fullfile(tifDir,[currFileName '.tif']));
        fprintf('Saving file %06i...\n',fileInd)
    end

    % Get regionprops for 3D, store in .mat file
    bwObjs = logical(currMat);
    rp3D = regionprops3(bwObjs, selFields3D);
    % Make filament properties calculated from regionprops
    catEVecs = [rp3D.EigenVectors{:}];
    % EVecs are returned in (row,col,page) form; swap x,y
    % Isolate every third column. Each evec is a column. 1st col is dir.
    catEVecs1 = catEVecs([2 1 3],1:3:end); 
    filDirs = catEVecs1';                   % Convert to rows
    filLens = [rp3D.PrincipalAxisLength(:,1)];
    filOffLens = [rp3D.PrincipalAxisLength(:,2:3)];
    filARs = filLens./filOffLens(:,1);
    % Append properties
    rp3D.('Directors') = filDirs;
    rp3D.('Lengths') = filLens;
    rp3D.('AspectRatios') = filARs;

    % Get regionprops for 2D, store in .mat file
    % Iterate through each Z slice, get 2D stats, store
    for zInd = 1:size(bwObjs,3)
        curr2D = regionprops(bwObjs(:,:,zInd),selFields2D);
        IndVecCol = repmat(zInd, size(curr2D,1), 1);
        curr2D = addFieldStruct(curr2D,'Slice_Index',IndVecCol);
        if (newBool == 1) && ~isempty(curr2D)
            rp2D = curr2D;
            newBool = 0;
        elseif (newBool == 0) && ~isempty(curr2D)
            rp2D = vertcat(rp2D,curr2D);
        end
    end
    save(fullfile(currSaveDir,sprintf('Filament Statistics %03i',fileInd)),"rp2D",'rp3D','scaleFacts','h5Thresh','h5Chans');
end
imgSize = size(currMat);
save(fullfile(currSaveDir,'FilamentDetect_metadata.mat'),"pixSize","h5Chans","h5Thresh",'imgSize')



